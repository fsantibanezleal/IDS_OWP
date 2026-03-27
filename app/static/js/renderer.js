/**
 * Canvas Renderer for OWP Application.
 *
 * Renders 2D arrays as colored grids on HTML5 canvas elements.
 * Supports binary fields, probability fields, entropy heatmaps,
 * and sample position overlays.
 */

const Renderer = {
    /**
     * Render a binary or probability field on a canvas.
     * 0 = dark (shale), 1 = light (sand/channel).
     *
     * @param {string} canvasId - Canvas element ID.
     * @param {number[][]} data - 2D array of values in [0, 1].
     * @param {object} options - Rendering options.
     */
    renderField(canvasId, data, options = {}) {
        const canvas = document.getElementById(canvasId);
        if (!canvas || !data || data.length === 0) return;

        const ctx = canvas.getContext('2d');
        const H = data.length;
        const W = data[0].length;

        const cellW = canvas.width / W;
        const cellH = canvas.height / H;

        ctx.clearRect(0, 0, canvas.width, canvas.height);

        for (let i = 0; i < H; i++) {
            for (let j = 0; j < W; j++) {
                const val = data[i][j];
                if (options.colormap === 'entropy') {
                    ctx.fillStyle = this._entropyColor(val);
                } else if (options.colormap === 'probability') {
                    ctx.fillStyle = this._probabilityColor(val);
                } else {
                    // Binary: black/white
                    const g = Math.round(val * 255);
                    ctx.fillStyle = `rgb(${g}, ${g}, ${g})`;
                }
                ctx.fillRect(j * cellW, i * cellH, cellW + 0.5, cellH + 0.5);
            }
        }

        // Draw sample positions if provided
        if (options.positions) {
            this.renderPositions(canvasId, options.positions, H, W, options.values);
        }
    },

    /**
     * Render sample positions as colored dots on a canvas.
     *
     * @param {string} canvasId - Canvas element ID.
     * @param {number[][]} positions - Array of [row, col] pairs.
     * @param {number} H - Field height.
     * @param {number} W - Field width.
     * @param {number[]} values - Optional sampled values for coloring.
     */
    renderPositions(canvasId, positions, H, W, values = null) {
        const canvas = document.getElementById(canvasId);
        if (!canvas) return;

        const ctx = canvas.getContext('2d');
        const cellW = canvas.width / W;
        const cellH = canvas.height / H;
        const radius = Math.max(2, Math.min(cellW, cellH) * 0.35);

        for (let k = 0; k < positions.length; k++) {
            const [r, c] = positions[k];
            const cx = (c + 0.5) * cellW;
            const cy = (r + 0.5) * cellH;

            // Color by value if available
            if (values && values[k] !== undefined) {
                ctx.fillStyle = values[k] > 0.5 ? '#34d399' : '#ef4444';
            } else {
                ctx.fillStyle = '#4a9eff';
            }

            ctx.beginPath();
            ctx.arc(cx, cy, radius, 0, 2 * Math.PI);
            ctx.fill();

            // White outline
            ctx.strokeStyle = 'white';
            ctx.lineWidth = 1;
            ctx.stroke();
        }
    },

    /**
     * Render a blank/empty canvas with a message.
     *
     * @param {string} canvasId - Canvas element ID.
     * @param {string} message - Message to display.
     */
    renderEmpty(canvasId, message = '') {
        const canvas = document.getElementById(canvasId);
        if (!canvas) return;

        const ctx = canvas.getContext('2d');
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        ctx.fillStyle = '#111827';
        ctx.fillRect(0, 0, canvas.width, canvas.height);

        if (message) {
            ctx.fillStyle = '#9aa0a6';
            ctx.font = '14px sans-serif';
            ctx.textAlign = 'center';
            ctx.fillText(message, canvas.width / 2, canvas.height / 2);
        }
    },

    /**
     * Render a "hidden" field (solid gray with question mark).
     *
     * @param {string} canvasId - Canvas element ID.
     */
    renderHidden(canvasId) {
        const canvas = document.getElementById(canvasId);
        if (!canvas) return;

        const ctx = canvas.getContext('2d');
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        ctx.fillStyle = '#1e2a3a';
        ctx.fillRect(0, 0, canvas.width, canvas.height);

        ctx.fillStyle = '#4a5568';
        ctx.font = 'bold 48px sans-serif';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText('?', canvas.width / 2, canvas.height / 2);

        ctx.font = '12px sans-serif';
        ctx.fillText('Click "Reveal" to show', canvas.width / 2, canvas.height / 2 + 40);
    },

    /**
     * Entropy colormap: blue (low) -> yellow (medium) -> red (high).
     * Maps entropy values [0, 1] to colors.
     */
    _entropyColor(val) {
        // Clamp to [0, 1]
        val = Math.max(0, Math.min(1, val));

        let r, g, b;
        if (val < 0.5) {
            // Blue to Yellow
            const t = val * 2;
            r = Math.round(t * 255);
            g = Math.round(t * 255);
            b = Math.round((1 - t) * 200 + 55);
        } else {
            // Yellow to Red
            const t = (val - 0.5) * 2;
            r = 255;
            g = Math.round((1 - t) * 255);
            b = Math.round((1 - t) * 55);
        }
        return `rgb(${r}, ${g}, ${b})`;
    },

    /**
     * Probability colormap: blue (0) -> white (0.5) -> red (1).
     */
    _probabilityColor(val) {
        val = Math.max(0, Math.min(1, val));

        let r, g, b;
        if (val < 0.5) {
            const t = val * 2;
            r = Math.round(t * 255);
            g = Math.round(t * 255);
            b = 255;
        } else {
            const t = (val - 0.5) * 2;
            r = 255;
            g = Math.round((1 - t) * 255);
            b = Math.round((1 - t) * 255);
        }
        return `rgb(${r}, ${g}, ${b})`;
    }
};
