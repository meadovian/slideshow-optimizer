# Slideshow Optimizer (slideshow-optimizer.sh)

A powerful command-line tool for creating optimized video slideshows from sequences of PNG images. Specifically designed for artists, content creators, and digital storytellers who need to create high-quality video presentations from image sequences.

## Features

- Handles varying image dimensions automatically
- Multiple optimization presets for different use cases
- Configurable frame durations
- Smooth transitions between frames
- Two-pass encoding option for superior quality
- Maintains aspect ratios
- White background padding for non-uniform dimensions
- Automatic sequential ordering of images

## Prerequisites

- macOS (tested on Sonoma 14.6)
- ffmpeg (required for video processing)

Install ffmpeg using Homebrew:
```bash
brew install ffmpeg
```

## Installation

1. Download the script:
```bash
curl -O https://[your-repository]/slideshow-optimizer.sh
```

2. Make it executable:
```bash
chmod +x slideshow-optimizer.sh
```

## Basic Usage

```bash
./slideshow-optimizer.sh /path/to/your/images
```

## Options

```
Options:
  -d, --duration SECONDS    Default duration per image (default: 2)
  -o, --output FILENAME     Output filename (default: output.mp4)
  -f, --framerate FPS      Output framerate (default: 30)
  -p, --preset NAME        Optimization preset (default: web-hd)
  -t, --transition SECONDS Fade transition duration (default: 0.5, 0 for no fade)
  --two-pass              Enable two-pass encoding for better compression
```

## Optimization Presets

| Preset | Description | Best For |
|--------|-------------|----------|
| web-small | Minimal file size (80% reduction) | Web embedding, email sharing |
| web-medium | Balanced quality (60% reduction) | General web usage |
| web-hd | High quality (30% reduction) | Professional web display |
| mobile | Mobile-optimized (70% reduction) | Mobile apps, messaging |
| social | Social media optimized (50% reduction) | Instagram, Twitter |
| archive | Maximum quality | Source material, archiving |

## Example Use Cases

1. **Art Portfolio Presentation**
```bash
./slideshow-optimizer.sh /path/to/artwork -p archive --two-pass -d 3 -t 1.0
```
This creates a high-quality video with:
- Maximum quality preservation
- 3-second display per image
- 1-second fade transitions
- Two-pass encoding for best quality
Perfect for showcasing detailed artwork where quality is crucial.

2. **Social Media Story**
```bash
./slideshow-optimizer.sh /path/to/images -p social -d 1.5 -t 0.3 -o instagram_story.mp4
```
This creates a social-media optimized video with:
- Balanced compression for social platforms
- Quick 1.5-second display per image
- Short 0.3-second transitions
- Optimized for mobile viewing
Ideal for Instagram stories or Twitter posts.

3. **Web Gallery Preview**
```bash
./slideshow-optimizer.sh /path/to/gallery -p web-small -d 2 -t 0.5 -f 24
```
This creates a lightweight web-optimized video with:
- Small file size for fast loading
- Standard 2-second display time
- Smooth 0.5-second transitions
- 24fps for web efficiency
Perfect for website embedding or email distribution.

## Working With Image Sequences

The script automatically:
1. Orders images by timestamp
2. Renames them sequentially (image001.png, image002.png, etc.)
3. Creates a durations.txt file for timing control
4. Handles varying image dimensions with intelligent scaling

## Customizing Frame Durations

1. Run the script initially
2. Edit the `durations.txt` file in the temporary directory
3. Format: `imageXXX.png=seconds`

Example durations.txt:
```
image001.png=3
image002.png=2.5
image003.png=4
```

## Best Practices

1. **Image Preparation**
   - Use high-quality PNG files
   - Clean filenames (avoid special characters)
   - Consider ordering by timestamp for sequence control

2. **Quality vs Size**
   - Use 'archive' preset for professional presentations
   - Use 'social' preset for social media
   - Use 'web-small' for email/messaging
   - Enable two-pass encoding for important outputs

3. **Performance**
   - Start with faster presets for testing
   - Use two-pass encoding only for final output
   - Monitor disk space during processing

## Troubleshooting

1. **Permission Issues**
```bash
chmod 644 /path/to/images/*.png
```

2. **Quality Issues**
   - Try archive preset
   - Enable two-pass encoding
   - Check source image quality

3. **Size Issues**
   - Try web-small preset
   - Reduce transition duration
   - Adjust framerate

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
- Check documentation for advanced usage
- Join the community discussions
