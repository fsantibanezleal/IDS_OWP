/**
 * WebSocket Client for OWP Application.
 *
 * Manages the WebSocket connection to the server for real-time
 * updates during adaptive sampling (AdSEMES).
 */

const WS = {
    /** @type {WebSocket|null} */
    socket: null,

    /** @type {boolean} */
    connected: false,

    /** @type {Function|null} Callback for step updates. */
    onStep: null,

    /** @type {Function|null} Callback for completion. */
    onComplete: null,

    /** @type {Function|null} Callback for errors. */
    onError: null,

    /**
     * Connect to the WebSocket server.
     *
     * @returns {Promise<void>}
     */
    connect() {
        return new Promise((resolve, reject) => {
            const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const url = `${protocol}//${window.location.host}/api/ws`;

            this.socket = new WebSocket(url);

            this.socket.onopen = () => {
                this.connected = true;
                console.log('[WS] Connected');
                resolve();
            };

            this.socket.onmessage = (event) => {
                const data = JSON.parse(event.data);

                if (data.status === 'complete') {
                    if (this.onComplete) this.onComplete(data);
                } else if (data.status === 'error') {
                    if (this.onError) this.onError(data.message);
                } else if (data.step !== undefined) {
                    if (this.onStep) this.onStep(data);
                }
            };

            this.socket.onclose = () => {
                this.connected = false;
                console.log('[WS] Disconnected');
            };

            this.socket.onerror = (err) => {
                console.error('[WS] Error:', err);
                reject(err);
            };
        });
    },

    /**
     * Send a message to the server.
     *
     * @param {object} data - JSON-serializable message.
     */
    send(data) {
        if (this.socket && this.connected) {
            this.socket.send(JSON.stringify(data));
        } else {
            console.warn('[WS] Not connected. Cannot send.');
        }
    },

    /**
     * Start adaptive sampling via WebSocket.
     *
     * @param {number} numSamples - Number of samples.
     * @param {number} patternRadius - Pattern radius for entropy estimation.
     */
    startAdaptiveSampling(numSamples, patternRadius) {
        this.send({
            action: 'adaptive_sample',
            num_samples: numSamples,
            pattern_radius: patternRadius,
        });
    },

    /**
     * Disconnect from the server.
     */
    disconnect() {
        if (this.socket) {
            this.socket.close();
            this.socket = null;
            this.connected = false;
        }
    }
};
