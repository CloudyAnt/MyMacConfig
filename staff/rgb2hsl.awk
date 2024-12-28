{
    r = $1 / 255; g = $2 / 255; b = $3 / 255
    cmax = r
    if (g > cmax) cmax = g
    if (b > cmax) cmax = b
    cmin = r
    if (g < cmin) cmin = g
    if (b < cmin) cmin = b
    delta = cmax - cmin

    l = (cmax + cmin) / 2

    if (delta == 0) {
        s = 0
        h = 0
    } else {
        if (l < 0.5) {
            s = delta / (cmax + cmin)
        } else {
            s = delta / (2 - cmax - cmin)
        }
        if (cmax == r) {
            h = (g - b) / delta
        } else if (cmax == g) {
            h = 2 + (b - r) / delta
        } else {
            h = 4 + (r - g) / delta
        }
        h *= 60
        if (h < 0) h += 360
    }
    printf "%.1f %.1f %.1f", h, s * 100, l * 100
}