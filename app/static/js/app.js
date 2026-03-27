/**
 * Main Application Logic for OWP.
 *
 * Orchestrates the UI, API calls, and visualization updates.
 */

(function () {
    'use strict';

    // ===== State =====
    let appState = {
        hasField: false,
        trueField: null,
        trainingImage: null,
        positions: null,
        sampledValues: null,
        entropyMap: null,
        reconstructed: null,
        trueRevealed: false,
        fieldShape: null,
    };

    // ===== DOM Elements =====
    const els = {
        fieldType: document.getElementById('fieldType'),
        fieldSize: document.getElementById('fieldSize'),
        samplingMethod: document.getElementById('samplingMethod'),
        numSamples: document.getElementById('numSamples'),
        numSamplesValue: document.getElementById('numSamplesValue'),
        patternRadius: document.getElementById('patternRadius'),
        patternRadiusValue: document.getElementById('patternRadiusValue'),
        reconMethod: document.getElementById('reconMethod'),
        generateBtn: document.getElementById('generateBtn'),
        sampleBtn: document.getElementById('sampleBtn'),
        inferBtn: document.getElementById('inferBtn'),
        revealBtn: document.getElementById('revealBtn'),
        status: document.getElementById('status'),
        helpBtn: document.getElementById('helpBtn'),
        helpModal: document.getElementById('helpModal'),
        closeHelp: document.getElementById('closeHelp'),
        metricsPanel: document.getElementById('metricsPanel'),
        trueFieldTitle: document.getElementById('trueFieldTitle'),
    };

    // ===== Event Listeners =====
    els.numSamples.addEventListener('input', () => {
        els.numSamplesValue.textContent = els.numSamples.value;
    });

    els.patternRadius.addEventListener('input', () => {
        els.patternRadiusValue.textContent = els.patternRadius.value;
    });

    els.generateBtn.addEventListener('click', generateField);
    els.sampleBtn.addEventListener('click', runSampling);
    els.inferBtn.addEventListener('click', runReconstruction);
    els.revealBtn.addEventListener('click', revealField);

    els.helpBtn.addEventListener('click', () => {
        els.helpModal.classList.remove('hidden');
    });
    els.closeHelp.addEventListener('click', () => {
        els.helpModal.classList.add('hidden');
    });
    els.helpModal.addEventListener('click', (e) => {
        if (e.target === els.helpModal) els.helpModal.classList.add('hidden');
    });

    // ===== Initialize =====
    initCanvases();

    // ===== Functions =====

    function initCanvases() {
        Renderer.renderEmpty('canvasTI', 'Training Image');
        Renderer.renderEmpty('canvasSampled', 'Sampled Positions');
        Renderer.renderEmpty('canvasEntropy', 'Entropy Map');
        Renderer.renderEmpty('canvasRecon', 'Reconstruction');
        Renderer.renderHidden('canvasTrue');
    }

    function setStatus(msg) {
        els.status.textContent = msg;
    }

    function setButtonsEnabled(generate, sample, infer, reveal) {
        els.generateBtn.disabled = !generate;
        els.sampleBtn.disabled = !sample;
        els.inferBtn.disabled = !infer;
        els.revealBtn.disabled = !reveal;
    }

    async function apiCall(endpoint, body) {
        const resp = await fetch(endpoint, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body),
        });
        return await resp.json();
    }

    async function generateField() {
        setStatus('Generating field...');
        setButtonsEnabled(false, false, false, false);

        const size = parseInt(els.fieldSize.value);
        const tiSize = Math.min(size * 2, 128);

        try {
            const result = await apiCall('/api/generate', {
                field_type: els.fieldType.value,
                field_height: size,
                field_width: size,
                ti_height: tiSize,
                ti_width: tiSize,
                seed: Math.floor(Math.random() * 100000),
            });

            if (result.status !== 'ok') {
                setStatus('Error: ' + (result.message || 'Generation failed'));
                setButtonsEnabled(true, false, false, false);
                return;
            }

            appState.hasField = true;
            appState.trainingImage = result.training_image;
            appState.entropyMap = result.entropy_map;
            appState.fieldShape = result.field_shape;
            appState.positions = null;
            appState.reconstructed = null;
            appState.trueField = null;
            appState.trueRevealed = false;

            // Render
            Renderer.renderField('canvasTI', result.training_image);
            Renderer.renderField('canvasEntropy', result.entropy_map, { colormap: 'entropy' });
            Renderer.renderEmpty('canvasSampled', 'Run sampling');
            Renderer.renderEmpty('canvasRecon', 'Run reconstruction');
            Renderer.renderHidden('canvasTrue');
            els.trueFieldTitle.textContent = 'True Field (Hidden)';

            updateMetrics(null);

            setStatus(
                `Field ${size}x${size} generated (${els.fieldType.value}). ` +
                `TI: ${tiSize}x${tiSize}. Proportion: ${(result.field_proportion * 100).toFixed(1)}%.`
            );
            setButtonsEnabled(true, true, false, false);

        } catch (err) {
            setStatus('Error: ' + err.message);
            setButtonsEnabled(true, false, false, false);
        }
    }

    async function runSampling() {
        const method = els.samplingMethod.value;
        const numSamples = parseInt(els.numSamples.value);
        const patternRadius = parseInt(els.patternRadius.value);

        setStatus(`Running ${method} sampling (${numSamples} samples)...`);
        setButtonsEnabled(false, false, false, false);

        // For adaptive_entropy, try WebSocket for real-time updates
        if (method === 'adaptive_entropy') {
            await runAdaptiveSamplingWS(numSamples, patternRadius);
            return;
        }

        try {
            const result = await apiCall('/api/sample', {
                method: method,
                num_samples: numSamples,
                pattern_radius: patternRadius,
                seed: Math.floor(Math.random() * 100000),
            });

            if (result.status !== 'ok') {
                setStatus('Error: ' + (result.message || 'Sampling failed'));
                setButtonsEnabled(true, true, false, false);
                return;
            }

            handleSamplingResult(result);

        } catch (err) {
            setStatus('Error: ' + err.message);
            setButtonsEnabled(true, true, false, false);
        }
    }

    function handleSamplingResult(result) {
        appState.positions = result.positions;
        appState.sampledValues = result.sampled_values;
        appState.entropyMap = result.entropy_map;
        appState.reconstructed = null;

        // Render sampled positions on empty field
        const [H, W] = appState.fieldShape;
        const emptyField = Array.from({ length: H }, () => Array(W).fill(0.3));
        Renderer.renderField('canvasSampled', emptyField, {
            positions: result.positions,
            values: result.sampled_values,
        });

        // Render entropy map
        if (result.entropy_map) {
            Renderer.renderField('canvasEntropy', result.entropy_map, { colormap: 'entropy' });
        }

        Renderer.renderEmpty('canvasRecon', 'Run reconstruction');
        updateMetrics(null);

        setStatus(
            `${result.method}: ${result.num_samples} samples placed. ` +
            `Entropy: ${result.current_entropy.toFixed(1)} bits.`
        );
        setButtonsEnabled(true, true, true, true);
    }

    async function runAdaptiveSamplingWS(numSamples, patternRadius) {
        try {
            await WS.connect();

            const [H, W] = appState.fieldShape;
            let stepPositions = [];
            let stepValues = [];

            WS.onStep = (data) => {
                stepPositions.push(data.position);
                stepValues.push(data.value);

                // Update sampled positions canvas
                const emptyField = Array.from({ length: H }, () => Array(W).fill(0.3));
                Renderer.renderField('canvasSampled', emptyField, {
                    positions: stepPositions,
                    values: stepValues,
                });

                // Update entropy map
                if (data.entropy_map) {
                    Renderer.renderField('canvasEntropy', data.entropy_map, { colormap: 'entropy' });
                }

                setStatus(
                    `AdSEMES step ${data.step + 1}/${numSamples}: ` +
                    `placed at (${data.position[0]}, ${data.position[1]}), ` +
                    `entropy: ${data.entropy_total.toFixed(1)} bits`
                );
            };

            WS.onComplete = (data) => {
                appState.positions = data.positions;
                appState.sampledValues = stepValues;
                appState.reconstructed = null;

                setStatus(`AdSEMES complete: ${data.num_samples} samples placed.`);
                setButtonsEnabled(true, true, true, true);
                WS.disconnect();
            };

            WS.onError = (msg) => {
                setStatus('WebSocket error: ' + msg);
                setButtonsEnabled(true, true, false, false);
                WS.disconnect();
            };

            WS.startAdaptiveSampling(numSamples, patternRadius);

        } catch (err) {
            // Fallback to REST API
            setStatus('WebSocket failed, using REST API...');
            try {
                const result = await apiCall('/api/sample', {
                    method: 'adaptive_entropy',
                    num_samples: numSamples,
                    pattern_radius: patternRadius,
                    seed: Math.floor(Math.random() * 100000),
                });
                if (result.status === 'ok') {
                    handleSamplingResult(result);
                } else {
                    setStatus('Error: ' + (result.message || 'Sampling failed'));
                    setButtonsEnabled(true, true, false, false);
                }
            } catch (e2) {
                setStatus('Error: ' + e2.message);
                setButtonsEnabled(true, true, false, false);
            }
        }
    }

    async function runReconstruction() {
        const method = els.reconMethod.value;
        setStatus(`Reconstructing with ${method}...`);
        setButtonsEnabled(false, false, false, false);

        try {
            const result = await apiCall('/api/infer', {
                method: method,
            });

            if (result.status !== 'ok') {
                setStatus('Error: ' + (result.message || 'Reconstruction failed'));
                setButtonsEnabled(true, true, true, true);
                return;
            }

            appState.reconstructed = result.reconstructed;
            appState.trueField = result.true_field;

            // Render reconstruction
            Renderer.renderField('canvasRecon', result.reconstructed, { colormap: 'probability' });

            // Update metrics
            updateMetrics(result.metrics);

            setStatus(
                `Reconstruction (${method}): ` +
                `SNR=${result.metrics.snr_db.toFixed(1)} dB, ` +
                `Accuracy=${(result.metrics.accuracy * 100).toFixed(1)}%`
            );
            setButtonsEnabled(true, true, true, true);

        } catch (err) {
            setStatus('Error: ' + err.message);
            setButtonsEnabled(true, true, true, true);
        }
    }

    function revealField() {
        if (appState.trueField) {
            appState.trueRevealed = true;
            Renderer.renderField('canvasTrue', appState.trueField);
            els.trueFieldTitle.textContent = 'True Field (Revealed)';

            // Also overlay sample positions on true field
            if (appState.positions) {
                const [H, W] = appState.fieldShape;
                Renderer.renderPositions('canvasTrue', appState.positions, H, W, appState.sampledValues);
            }
        } else {
            setStatus('Reconstruct first to get the true field data.');
        }
    }

    function updateMetrics(metrics) {
        if (!metrics) {
            els.metricsPanel.innerHTML = '<p class="placeholder">Run sampling and reconstruction to see metrics.</p>';
            return;
        }

        const fmt = (v, dec = 2) => {
            if (v === Infinity) return 'Inf';
            if (typeof v === 'number') return v.toFixed(dec);
            return String(v);
        };

        const classify = (v, good, moderate) => {
            if (v >= good) return 'good';
            if (v >= moderate) return 'moderate';
            return 'poor';
        };

        const rows = [
            { label: 'SNR', value: fmt(metrics.snr_db, 1) + ' dB', cls: classify(metrics.snr_db, 10, 5) },
            { label: 'MSE', value: fmt(metrics.mse, 4), cls: classify(1 - metrics.mse, 0.9, 0.7) },
            { label: 'Accuracy', value: fmt(metrics.accuracy * 100, 1) + '%', cls: classify(metrics.accuracy, 0.85, 0.7) },
            { label: 'Precision', value: fmt(metrics.cm_precision * 100, 1) + '%', cls: classify(metrics.cm_precision, 0.8, 0.6) },
            { label: 'Recall', value: fmt(metrics.cm_recall * 100, 1) + '%', cls: classify(metrics.cm_recall, 0.8, 0.6) },
            { label: 'F1 Score', value: fmt(metrics.cm_f1 * 100, 1) + '%', cls: classify(metrics.cm_f1, 0.8, 0.6) },
            { label: 'Coverage (5px)', value: fmt(metrics.coverage_5px * 100, 1) + '%', cls: classify(metrics.coverage_5px, 0.9, 0.7) },
            { label: 'Pattern Pres.', value: fmt(metrics.pattern_preservation * 100, 1) + '%', cls: classify(metrics.pattern_preservation, 0.85, 0.7) },
        ];

        if (metrics.resolvability !== undefined) {
            rows.push({
                label: 'Resolvability',
                value: fmt(metrics.resolvability * 100, 1) + '%',
                cls: classify(metrics.resolvability, 0.5, 0.2),
            });
        }

        els.metricsPanel.innerHTML = rows.map(r =>
            `<div class="metric-row"><span class="label">${r.label}</span><span class="value ${r.cls}">${r.value}</span></div>`
        ).join('');
    }

})();
