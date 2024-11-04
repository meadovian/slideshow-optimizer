# Add these new defaults at the top of the script
DEFAULT_QUALITY="medium"     # Quality preset (low|medium|high)
DEFAULT_RESOLUTION="100"     # Resolution percentage (e.g., 50 for half size)
DEFAULT_CRF=23              # Constant Rate Factor (18-28, higher = smaller file)
DEFAULT_PRESET="medium"     # Encoding preset (ultrafast|fast|medium|slow|veryslow)

# Modify the help function to add new options
show_help() {
    # ... (existing help content) ...
    echo "  -q, --quality QUALITY     Quality preset (low|medium|high, default: $DEFAULT_QUALITY)"
    echo "  -r, --resolution PERCENT  Resolution percentage (default: $DEFAULT_RESOLUTION)"
    echo "  --crf VALUE              Constant Rate Factor (18-28, default: $DEFAULT_CRF)"
    echo "  --preset PRESET          Encoding preset (ultrafast|fast|medium|slow|veryslow)"
}

# Modify the quality presets in the script
case $DEFAULT_QUALITY in
    low)
        QUALITY_PARAMS="-preset faster -crf 28 -b:v 1000k"
        ;;
    medium)
        QUALITY_PARAMS="-preset medium -crf 23 -b:v 2000k"
        ;;
    high)
        QUALITY_PARAMS="-preset slower -crf 18 -b:v 4000k"
        ;;
esac

create_video() {
    # ... (existing setup code) ...
    
    # Calculate dimensions based on resolution percentage
    MAX_WIDTH=$((MAX_WIDTH * DEFAULT_RESOLUTION / 100))
    MAX_HEIGHT=$((MAX_HEIGHT * DEFAULT_RESOLUTION / 100))
    
    # Ensure even dimensions
    MAX_WIDTH=$((MAX_WIDTH - MAX_WIDTH % 2))
    MAX_HEIGHT=$((MAX_HEIGHT - MAX_HEIGHT % 2))
    
    # Modify the ffmpeg command to add optimization parameters
    CMD="ffmpeg -y -hide_banner -loglevel info $INPUTS \
        -filter_complex \"$FILTER_COMPLEX\" \
        -map \"[outv]\" \
        -c:v libx264 \
        ${QUALITY_PARAMS} \
        -pix_fmt yuv420p \
        -movflags +faststart \
        -tune stillimage \
        -r $DEFAULT_FRAMERATE \
        \"$OUTPUT_FILENAME\""
    
    # ... (rest of the function)
}
