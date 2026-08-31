/**
 * Chrono Plugin - plugin.js
 * Bridge for the Chrono side-panel plugin.
 */

PluginAPI.registerHeaderButton({
  label: 'Chrono',
  icon: 'timer',
  onClick: () => {
    PluginAPI.showIndexHtmlAsView();
  },
});

PluginAPI.registerShortcut({
  id: 'show_chrono',
  label: 'Show Chrono',
  onExec: function () {
    PluginAPI.showIndexHtmlAsView();
  },
});

PluginAPI.registerHook(PluginAPI.Hooks.ACTION, (action) => {
  const iframes = document.querySelectorAll('iframe');
  iframes.forEach((iframe) => {
    if (iframe.src && iframe.src.includes('chrono')) {
      iframe.contentWindow.postMessage({ type: 'SP_ACTION', action: action }, '*');
    }
  });
});
