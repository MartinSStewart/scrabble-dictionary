exports.init = async function (app) {
    app.ports.requestWakeLock.subscribe(async function () {
        await acquireWakeLock();
    });

    async function acquireWakeLock() {
        if ('wakeLock' in navigator) {
            try {
                await navigator.wakeLock.request('screen');
            } catch (err) {
                // Wake lock request failed - usually happens when document is not visible
                // or battery saver mode is active. Silently ignore.
                console.log('Wake lock request failed:', err.message);
            }
        }
    }
};
