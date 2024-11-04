# Slideshow Optimizer (slideshow-optimizer.sh)

A powerful command-line tool for creating optimized video slideshows from sequences of PNG images. Designed for content creators, digital artists, and anyone needing to create efficient video presentations from image sequences.

## Overview

Slideshow Optimizer converts a series of PNG images into an optimized video slideshow, with features including:
- Multiple optimization presets for different use cases
- Configurable image durations
- Smooth transitions
- Two-pass encoding for superior compression
- Platform-specific output profiles

## Installation

1. Download the script:
```bash
curl -O https://[your-repository]/slideshow-optimizer.sh
```

2. Make it executable:
```bash
chmod +x slideshow-optimizer.sh
```

3. Ensure ffmpeg is installed:
```bash
brew install ffmpeg
```

## Basic Usage

```bash
./slideshow-optimizer.sh /path/to/your/images
```

## Optimization Presets

Choose from several optimization presets designed for different use cases:

| Preset | Description | Use Case |
|--------|-------------|----------|
| web-small | Minimal file size (80% reduction) | Web embedding, email sharing |
| web-medium | Balanced quality (60% reduction) | General web usage |
| web-hd | High quality (30% reduction) | Professional web display |
| mobile | Mobile-optimized (70% reduction) | Mobile apps, WhatsApp |
| social | Social media optimized (50% reduction) | Instagram, Twitter |
| archive | Maximum quality | Archival, source material |

### Using Presets

```bash
# For social media
./slideshow-optimizer.sh /path/to/images -p social

# For maximum quality
./slideshow-optimizer.sh /path/to/images -p archive --two-pass
```

## Advanced Options

```bash
Options:
  -d, --duration SECONDS    Default duration per image (default: 2)
  -o, --output FILENAME     Output filename (default: output.mp4)
  -f, --framerate FPS       Output framerate (default: 30)
  -p, --preset NAME         Optimization preset (default: web-hd)
  -t, --transition SECONDS  Fade transition duration (default: 0.5, 0 for no fade)
  --two-pass               Enable two-pass encoding for better compression
  -h, --help               Show help message
```

## Customizing Image Durations

1. Run the script initially
2. Edit the `durations.txt` file in the temporary directory
3. Format: `imageXXX.png=seconds`

Example durations.txt:
```
image001.png=3
image002.png=2.5
image003.png=4
```

## Output Specifications

Each preset produces different output characteristics:

### web-small
- Resolution: 50% of original
- High compression (CRF 28)
- Fast encoding
- Target bitrate: 1000k

### web-medium
- Resolution: 75% of original
- Medium compression (CRF 23)
- Standard encoding
- Target bitrate: 2000k

### web-hd
- Full resolution
- Light compression (CRF 21)
- Standard encoding
- Target bitrate: 4000k

### mobile
- Resolution: 60% of original
- Balanced compression (CRF 26)
- Fast encoding
- Target bitrate: 1500k

### social
- Resolution: 85% of original
- Balanced compression (CRF 24)
- Standard encoding
- Target bitrate: 2500k

### archive
- Full resolution
- Minimal compression (CRF 18)
- Slow, high-quality encoding
- Target bitrate: 8000k

## Two-Pass Encoding

Enable two-pass encoding for better compression:
```bash
./slideshow-optimizer.sh /path/to/images --two-pass
```

Benefits:
- Better quality at same file size
- More consistent quality
- Better handling of complex transitions
- Recommended for final outputs

## Examples

1. Quick social media video:
```bash
./slideshow-optimizer.sh ~/Pictures/event -p social -t 0.5
```

2. High-quality archive:
```bash
./slideshow-optimizer.sh ~/Pictures/artwork -p archive --two-pass
```

3. Web embedding with custom duration:
```bash
./slideshow-optimizer.sh ~/Pictures/slides -p web-small -d 3
```

## Best Practices

1. **Image Preparation**
   - Use consistent image dimensions when possible
   - Ensure PNGs are properly optimized
   - Name files consistently for proper sequencing

2. **Preset Selection**
   - Use web-small for email/messaging
   - Use social for social media platforms
   - Use archive for source material
   - Use two-pass for important final outputs

3. **Performance**
   - Start with faster presets for testing
   - Use two-pass encoding only for final output
   - Monitor disk space during processing

## Troubleshooting

1. **Permission Errors**
```bash
chmod 644 /path/to/images/*.png
chmod 644 /path/to/images/tmp/durations.txt
```

2. **Memory Issues**
   - Use web-small preset
   - Reduce input image dimensions
   - Ensure sufficient free disk space

3. **Quality Issues**
   - Try two-pass encoding
   - Use a higher-quality preset
   - Check input image quality

## Contributing

See CONTRIBUTING.md for guidelines on:
- Reporting bugs
- Requesting features
- Submitting pull requests
- Code style requirements

## License

MIT License - See LICENSE.md for details.

## Support

- Report issues on GitHub
- Check the wiki for advanced usage
- Join the community discussions
