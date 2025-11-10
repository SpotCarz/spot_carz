const exifParser = require('exif-parser');

/**
 * Extracts EXIF metadata from image buffer
 * @param {Buffer} imageBuffer - Image file buffer
 * @returns {Object} Metadata object with camera info, GPS, timestamp, etc.
 */
function extractExifMetadata(imageBuffer) {
  try {
    const parser = exifParser.create(imageBuffer);
    const result = parser.parse();

    if (!result || !result.tags) {
      return {
        hasMetadata: false,
        metadata: {},
        status: 'missing',
      };
    }

    const tags = result.tags;
    const metadata = {
      // Camera information
      make: tags.Make || null,
      model: tags.Model || null,
      software: tags.Software || null,
      
      // Image properties
      width: tags.ImageWidth || null,
      height: tags.ImageHeight || null,
      orientation: tags.Orientation || null,
      
      // Date and time
      dateTime: tags.DateTime || tags.DateTimeOriginal || tags.DateTimeDigitized || null,
      
      // GPS information
      gps: null,
    };

    // Extract GPS data if available
    if (tags.GPSLatitude && tags.GPSLongitude) {
      metadata.gps = {
        latitude: tags.GPSLatitude,
        longitude: tags.GPSLongitude,
        altitude: tags.GPSAltitude || null,
      };
    }

    // Determine metadata status
    let status = 'missing';
    const hasCameraInfo = metadata.make && metadata.model;
    const hasDateTime = metadata.dateTime !== null;
    const hasGps = metadata.gps !== null;

    if (hasCameraInfo && hasDateTime && hasGps) {
      status = 'complete';
    } else if (hasCameraInfo || hasDateTime || hasGps) {
      status = 'partial';
    }

    return {
      hasMetadata: true,
      metadata: metadata,
      status: status,
    };
  } catch (error) {
    console.error('EXIF extraction error:', error);
    return {
      hasMetadata: false,
      metadata: {},
      status: 'missing',
      error: error.message,
    };
  }
}

module.exports = {
  extractExifMetadata,
};

