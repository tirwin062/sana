<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sana</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  html, body {
    width: 100%; height: 100vh;
    background: transparent;
    overflow: hidden;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  }
  /* Sana runs invisibly — only her face + bubble are visible */
</style>
</head>
<body>

<script>
// Configure SanaOS to connect to local bridge
window._sanaOSConfig = {
  appId:     'sana-local',
  bridgeUrl: 'ws://127.0.0.1:7433',
  mode:      'ambient'
};

// Configure SanaInvoke
window._sanaInvokeConfig = {
  appId:           'sana-local',
  subject:         'General',
  floatingTrigger: true,
  keyboardTrigger: true,
  prebootDelay:    200
};
</script>

<!-- Sana Intelligence Bundle -->
<script src="/sana-bundle-v11.js"></script>

<script>
(function bootSana() {
  'use strict';

  var config = window._sanaOSConfig;

  // Boot sequence — mirrors SanaInvoke's silent pre-boot
  var bootSteps = [
    function() { if (typeof SanaOS !== 'undefined') SanaOS.init(config); },
    function() { if (typeof SanaCognitive !== 'undefined') SanaCognitive.init(); },
    function() { if (typeof SanaEthics !== 'undefined') SanaEthics.init(); },
    function() { if (typeof SanaVoice !== 'undefined') SanaVoice.init(); },
    function() { if (typeof SanaAdapt !== 'undefined') SanaAdapt.init(); },
    function() { if (typeof SanaMind !== 'undefined') SanaMind.init(); },
    function() { if (typeof SanaSecurity !== 'undefined') SanaSecurity.init(); },
    function() {
      if (typeof SanaInvoke !== 'undefined') {
        SanaInvoke.init(window._sanaInvokeConfig);
      }
    }
  ];

  bootSteps.forEach(function(step, i) {
    try { step(); }
    catch(e) { console.warn('[Sana] Boot step ' + i + ' error:', e.message); }
  });

  console.log(
    '%c[Sana] Ready%c  Press Alt+S or click 🧠 to call her',
    'color:#7c3aed;font-weight:700;font-size:13px;',
    'color:#888;font-size:12px;'
  );

})();
</script>

</body>
</html>
