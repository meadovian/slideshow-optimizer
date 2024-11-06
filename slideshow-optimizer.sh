#!/bin/bash

# slideshow-optimizer.sh
# Creates optimized video slideshows from PNG image sequences
# Version 1.0.0

# Default values
DEFAULT_DURATION=2          # Default duration per image in seconds
DEFAULT_FRAMERATE=30        # Default output framerate
DEFAULT_OUTPUT="output.mp4" # Default output filename
DEFAULT_FADE=0.5           # Default fade duration in seconds (0 for no fade)
DEFAULT_PRESET="web-hd"    # Default optimization preset
MIN_DISK_SPACE=1000000     # Minimum required disk space in KB
MIN_RAM=1000000           # Minimum required RAM in KB

# Error codes
E_SUCCESS=0
E_GENERAL=1
E_NO_FFMPEG=2
E_NO_SPACE=3
E_NO_IMAGES=4
E_PERMISSION=5
E_INVALID_PRESET=6

# Optimization presets (using simpler array structure)
get_preset_settings() {
    local preset="$1"
    case "$preset" in
        "web-small")
            echo "resolution=50,crf=28,preset=faster,maxrate=1000k,bufsize=2000k"
            ;;
        "web-medium")
            echo "resolution=75,crf=23,preset=medium,maxrate=2000k,bufsize=4000k"
            ;;
        "web-hd")
            echo "resolution=100,crf=21,preset=medium,maxrate=4000k,bufsize=8000k"
            ;;
        "mobile")
            echo "resolution=60,crf=26,preset=faster,maxrate=1500k,bufsize=3000k"
            ;;
        "social")
            echo "resolution=85,crf=24,preset=medium,maxrate=2500k,bufsize=5000k"
            ;;
        "archive")
            echo "resolution=100,crf=18,preset=slow,maxrate=8000k,bufsize=16000k"
            ;;
        *)
            return 1
            ;;
    esac
}

# Help function
show_help() {
    cat << EOF
Slideshow Optimizer (slideshow-optimizer.sh)
Creates optimized video slideshows from PNG image sequences.

Usage: $(basename "$0") /path/to/images/directory [options]

Options:
  -d, --duration SECONDS    Default duration per image (default: $DEFAULT_DURATION)
  -o, --output FILENAME     Output filename (default: $DEFAULT_OUTPUT)
  -f, --framerate FPS      Output framerate (default: $DEFAULT_FRAMERATE)
  -p, --preset NAME        Optimization preset (default: $DEFAULT_PRESET)
  -t, --transition SECONDS Fade transition duration (default: $DEFAULT_FADE, 0 for no fade)
  --two-pass              Enable two-pass encoding for better compression
  -h, --help              Show this help message

Available Presets:
  web-small  - Small file size, good for web embedding
  web-medium - Balanced quality and size for web
  web-hd     - High quality for web viewing
  mobile     - Optimized for mobile devices
  social     - Optimized for social media platforms
  archive    - Maximum quality, larger file size

Example:
  $(basename "$0") ~/Desktop/my_images -p social --two-pass
EOF
}

# Logging functions
log_error() {
    echo "ERROR: $1" >&2
}

log_debug() {
    if [ "${DEBUG:-0}" -eq 1 ]; then
        echo "DEBUG: $1"
    fi
}

log_info() {
    echo "INFO: $1"
}

# System checks
check_requirements() {
    # Check for ffmpeg
    if ! command -v ffmpeg &> /dev/null; then
        log_error "ffmpeg is not installed. Please install it using: brew install ffmpeg"
        return $E_NO_FFMPEG
    fi

    # Check available disk space
    local available_space
    available_space=$(df -k . | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt "$MIN_DISK_SPACE" ]; then
        log_error "Insufficient disk space. Need at least $(($MIN_DISK_SPACE/1024))MB"
        return $E_NO_SPACE
    fi

    # Check available RAM
    local available_ram
    if [[ "$OSTYPE" == "darwin"* ]]; then
        available_ram=$(vm_stat | awk '/free/ {print $3*4096}')
    else
        available_ram=$(free | awk '/Mem:/ {print $7*1024}')
    fi
    if [ "${available_ram:-0}" -lt "$MIN_RAM" ]; then
        log_error "Low memory condition detected. This might affect performance."
    fi

    return $E_SUCCESS
}

# Parse preset settings
parse_preset() {
    local preset_string
    preset_string=$(get_preset_settings "$1")
    if [ $? -ne 0 ]; then
        log_error "Invalid preset: $1"
        return $E_INVALID_PRESET
    fi
    
    # Parse the preset string into variables
    IFS=',' read -r -a settings <<< "$preset_string"
    for setting in "${settings[@]}"; do
        IFS='=' read -r key value <<< "$setting"
        case "$key" in
            resolution) RESOLUTION="$value" ;;
            crf) CRF="$value" ;;
            preset) ENCODE_PRESET="$value" ;;
            maxrate) MAXRATE="$value" ;;
            bufsize) BUFSIZE="$value" ;;
        esac
    done

    return $E_SUCCESS
}

# Prepare working directory
prepare_working_directory() {
    log_info "Preparing working directory..."
    
    # Create tmp directory
    mkdir -p "$TMP_DIR"
    
    # Copy and rename PNG files sequentially based on timestamp
    local count=1
    find "$WORK_DIR" -maxdepth 1 -name "*.png" -type f -print0 | \
        sort -z | while IFS= read -r -d '' img; do
        filename=$(printf "image%03d.png" $count)
        cp "$img" "$TMP_DIR/$filename"
        log_info "Copied $(basename "$img") → $filename"
        ((count++))
    done
    
    # Create a durations file if it doesn't exist
    if [ ! -f "$TMP_DIR/durations.txt" ]; then
        find "$TMP_DIR" -name "*.png" -type f -print0 | \
            sort -z | while IFS= read -r -d '' img; do
            echo "$(basename "$img")=$DEFAULT_DURATION" >> "$TMP_DIR/durations.txt"
        done
    fi
    
    # Verify files were copied
    if [ ! "$(find "$TMP_DIR" -name "*.png" | wc -l)" -gt 0 ]; then
        log_error "Failed to copy PNG files to temporary directory"
        return $E_GENERAL
    fi
    
    log_info "Prepared working directory with $(find "$TMP_DIR" -name "*.png" | wc -l) images"
    return $E_SUCCESS
}

# Image validation
validate_images() {
    local dir="$1"
    local png_count=0
    local min_width=999999
    local max_width=0
    local min_height=999999
    local max_height=0

    while IFS= read -r -d '' img; do
        ((png_count++))
        
        # Check image validity and dimensions
        if ! ffprobe -v error "$img" &>/dev/null; then
            log_error "Invalid or corrupted image: $img"
            continue
        fi

        # Get dimensions
        local width height
        width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$img")
        height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$img")

        # Update min/max dimensions
        ((width < min_width)) && min_width=$width
        ((width > max_width)) && max_width=$width
        ((height < min_height)) && min_height=$height
        ((height > max_height)) && max_height=$height
    done < <(find "$dir" -maxdepth 1 -type f -name "*.png" -print0)

    if [ "$png_count" -eq 0 ]; then
        log_error "No PNG files found in $dir"
        return $E_NO_IMAGES
    fi

    # Warn about inconsistent dimensions
    if [ "$min_width" != "$max_width" ] || [ "$min_height" != "$max_height" ]; then
        log_info "Warning: Images have varying dimensions (${min_width}x${min_height} to ${max_width}x${max_height})"
    fi

    return $E_SUCCESS
}

# Create video with two-pass encoding
create_video_two_pass() {
    local filter_complex="$1"
    local inputs="$2"
    local output="$3"
    
    log_info "Starting first pass..."
    if ! eval ffmpeg -y -hide_banner -loglevel info $inputs \
        -filter_complex "$filter_complex" \
        -map "[outv]" \
        -c:v libx264 \
        -preset "$ENCODE_PRESET" \
        -crf "$CRF" \
        -maxrate "$MAXRATE" \
        -bufsize "$BUFSIZE" \
        -pix_fmt yuv420p \
        -tune stillimage \
        -r "$DEFAULT_FRAMERATE" \
        -f null \
        -pass 1 \
        -passlogfile "$PROCESS_DIR/passlog" \
        /dev/null; then
        return $E_GENERAL
    fi
    
    log_info "Starting second pass..."
    if ! eval ffmpeg -y -hide_banner -loglevel info $inputs \
        -filter_complex "$filter_complex" \
        -map "[outv]" \
        -c:v libx264 \
        -preset "$ENCODE_PRESET" \
        -crf "$CRF" \
        -maxrate "$MAXRATE" \
        -bufsize "$BUFSIZE" \
        -pix_fmt yuv420p \
        -tune stillimage \
        -r "$DEFAULT_FRAMERATE" \
        -pass 2 \
        -passlogfile "$PROCESS_DIR/passlog" \
        "$output"; then
        return $E_GENERAL
    fi

    return $E_SUCCESS
}

# Main video creation function
create_video() {
    cd "$TMP_DIR" || exit $E_GENERAL
    
    # Create temporary directory for processing
    PROCESS_DIR="$TMP_DIR/processing"
    mkdir -p "$PROCESS_DIR"
    
    # Parse the selected preset
    if ! parse_preset "$DEFAULT_PRESET"; then
        exit $E_INVALID_PRESET
    fi
    
    log_debug "Using preset: $DEFAULT_PRESET"
    log_debug "Resolution: ${RESOLUTION}%"
    log_debug "CRF: $CRF"
    log_debug "Encode preset: $ENCODE_PRESET"
    log_debug "Max rate: $MAXRATE"
    log_debug "Buffer size: $BUFSIZE"
    
    # Get and adjust dimensions
    local first_png
    first_png=$(find "$TMP_DIR" -name "*.png" -type f | head -n 1)
    
    if [ ! -f "$first_png" ]; then
        log_error "No PNG files found in directory"
        exit $E_NO_IMAGES
    fi
    
    # Get dimensions with error checking
    if ! MAX_WIDTH=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$first_png"); then
        log_error "Failed to get image dimensions"
        exit $E_GENERAL
    fi
    if ! MAX_HEIGHT=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$first_png"); then
        log_error "Failed to get image dimensions"
        exit $E_GENERAL
    fi

    # Apply resolution scaling
    MAX_WIDTH=$((MAX_WIDTH * RESOLUTION / 100))
    MAX_HEIGHT=$((MAX_HEIGHT * RESOLUTION / 100))
    
    # Ensure even dimensions
    MAX_WIDTH=$((MAX_WIDTH - MAX_WIDTH % 2))
    MAX_HEIGHT=$((MAX_HEIGHT - MAX_HEIGHT % 2))
    
    log_debug "Target dimensions: ${MAX_WIDTH}x${MAX_HEIGHT}"
    
    # Build the complex filter string
    FILTER_COMPLEX=""
    INPUTS=""
    count=0
    
# Process each image
    while IFS= read -r -d '' img; do
        if [ -f "$img" ] && [ -r "$img" ]; then
            # Get duration from durations.txt
            if [ -r "durations.txt" ]; then
                duration=$(grep "^$(basename "$img")=" durations.txt | cut -d= -f2)
            else
                duration=$DEFAULT_DURATION
            fi
            
            duration=${duration:-$DEFAULT_DURATION}
            
            # Add input file
            INPUTS="$INPUTS -loop 1 -t $duration -i \"$img\""
            
            # Add to filter complex with optional fade transition
            if [ $count -gt 0 ] && [ "$(echo "$DEFAULT_FADE > 0" | bc -l)" -eq 1 ]; then
                FILTER_COMPLEX="$FILTER_COMPLEX[$count:v]scale=w='min($MAX_WIDTH,iw)':h='min($MAX_HEIGHT,ih)':force_original_aspect_ratio=1,pad=$MAX_WIDTH:$MAX_HEIGHT:(ow-iw)/2:(oh-ih)/2:white,setsar=1:1,format=yuva420p,fade=in:st=0:d=${DEFAULT_FADE}:alpha=1[v${count}];"
            else
                FILTER_COMPLEX="$FILTER_COMPLEX[$count:v]scale=w='min($MAX_WIDTH,iw)':h='min($MAX_HEIGHT,ih)':force_original_aspect_ratio=1,pad=$MAX_WIDTH:$MAX_HEIGHT:(ow-iw)/2:(oh-ih)/2:white,setsar=1:1[v$count];"
            fi
            
            log_info "Processing $(basename "$img") (duration: $duration seconds)"
            ((count++))
        fi
    done < <(find . -maxdepth 1 -name "*.png" -type f -print0 | sort -z)
    
    # Add the concat filter
    for ((i=0; i<count; i++)); do
        FILTER_COMPLEX="$FILTER_COMPLEX[v$i]"
    done
    FILTER_COMPLEX="${FILTER_COMPLEX}concat=n=$count:v=1:a=0[outv]"
    
    # Create video using two-pass encoding if requested
    if [ "${TWO_PASS:-0}" -eq 1 ]; then
        if ! create_video_two_pass "$FILTER_COMPLEX" "$INPUTS" "$OUTPUT_FILENAME"; then
            log_error "Two-pass encoding failed"
            exit $E_GENERAL
        fi
    else
		# Inside create_video function, modify the ffmpeg command to use the full path with filename:
		CMD="ffmpeg -y -hide_banner -loglevel info $INPUTS \
		    -filter_complex \"$FILTER_COMPLEX\" \
		    -map \"[outv]\" \
		    -c:v libx264 \
		    -preset $ENCODE_PRESET \
		    -crf $CRF \
		    -maxrate $MAXRATE \
		    -bufsize $BUFSIZE \
		    -pix_fmt yuv420p \
		    -tune stillimage \
		    -movflags +faststart \
		    -r $DEFAULT_FRAMERATE \
		    \"${WORK_DIR}/${DEFAULT_OUTPUT}\""
		
		# And earlier in the script (near the top with other defaults), make sure we have:
        
        log_info "Creating video..."
        if ! eval "$CMD"; then
            log_error "Video creation failed"
            exit $E_GENERAL
        fi
    fi
    
	# After the ffmpeg command in create_video function:
    
    # Check if video was created successfully
    if [ ! -f "${WORK_DIR}/${DEFAULT_OUTPUT}" ]; then
        log_error "Failed to create final video"
        exit $E_GENERAL
    fi
    
    # Calculate and display output file size
    output_size=$(ls -lh "${WORK_DIR}/${DEFAULT_OUTPUT}" | awk '{print $5}')
    
    log_info "Video created successfully: ${WORK_DIR}/${DEFAULT_OUTPUT}"
    log_info "Processed $count images"
    log_info "Final video dimensions: ${MAX_WIDTH}x${MAX_HEIGHT}"
    log_info "Preset used: $DEFAULT_PRESET"
    log_info "Output file size: $output_size"
    
    # Cleanup
    log_info "Cleaning up temporary files..."
    rm -rf "$PROCESS_DIR"
    
    return $E_SUCCESS
}

# Parse command line arguments
parse_arguments() {
    POSITIONAL_ARGS=()
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--duration)
                DEFAULT_DURATION="$2"
                shift 2
                ;;
            -o|--output)
                DEFAULT_OUTPUT="$2"
                shift 2
                ;;
            -f|--framerate)
                DEFAULT_FRAMERATE="$2"
                shift 2
                ;;
            -p|--preset)
                DEFAULT_PRESET="$2"
                shift 2
                ;;
            -t|--transition)
                DEFAULT_FADE="$2"
                shift 2
                ;;
            --two-pass)
                TWO_PASS=1
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*|--*)
                log_error "Unknown option $1"
                show_help
                exit $E_GENERAL
                ;;
            *)
                POSITIONAL_ARGS+=("$1")
                shift
                ;;
        esac
    done

    # Restore positional parameters
    set -- "${POSITIONAL_ARGS[@]}"
    
    # Get working directory
    WORK_DIR="$1"
    if [ -z "$WORK_DIR" ]; then
        log_error "Please provide the path to the images directory"
        show_help
        exit $E_GENERAL
    fi
    
    if [ ! -d "$WORK_DIR" ]; then
        log_error "Directory $WORK_DIR does not exist"
        exit $E_GENERAL
    fi
}

# Main execution
main() {
    # Check system requirements
    if ! check_requirements; then
        exit $?
    fi

    # Parse command line arguments
    parse_arguments "$@"

    # Create working directory
    TMP_DIR="$WORK_DIR/tmp"
    mkdir -p "$TMP_DIR"

    # Validate input images
    if ! validate_images "$WORK_DIR"; then
        exit $?
    fi

    # Prepare working directory
    if ! prepare_working_directory; then
        exit $E_GENERAL
    fi

    echo ""
    read -p "Ready to create video? [y/N] " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        if ! create_video; then
            exit $?
        fi
    else
        echo "Exiting. You can modify durations in $WORK_DIR/tmp/durations.txt and run the script again."
        exit 0
    fi
}

# Start script
main "$@"
