# 0358 App icon artwork

The owner's art sits on a near-white rounded square. The script finds the art box by scanning for the white border, crops the largest centred square, then flood-fills the white outside region from the crop edge, grows it 4 px to remove the anti-aliased rim, and fills it from the nearest art pixel.

Chosen over insetting the crop: insetting far enough to hide the ~240 px corner radius would risk clipping the play triangle and tripod feet. A first attempt that clamped to a circular arc left white corners and a white rim, because the real corner shape is not a circle; the flood fill follows the actual shape.

Output is written as 24-bit RGB (no alpha) with an sRGB profile. `Tools/IconRenderer` stays as a fallback.
