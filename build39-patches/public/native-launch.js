(() => {
  const KEY = 'little-grove-v1';

  function valid(raw){
    if(!raw) return null;
    try{
      const value = JSON.parse(raw);
      return value && Array.isArray(value.sessions) && Array.isArray(value.decor) && value.settings ? value : null;
    }catch{
      return null;
    }
  }

  function newer(browserRaw, nativeRaw){
    const browser = valid(browserRaw);
    const native = valid(nativeRaw);
    if(!browser) return nativeRaw || null;
    if(!native) return browserRaw || null;
    const browserSessions = browser.sessions?.length || 0;
    const nativeSessions = native.sessions?.length || 0;
    if(browserSessions !== nativeSessions) return browserSessions > nativeSessions ? browserRaw : nativeRaw;
    const bt = Number(browser.savedAt) || 0;
    const nt = Number(native.savedAt) || 0;
    return nt > bt ? nativeRaw : browserRaw;
  }

  const nativeRaw = window.__POMOLAND_NATIVE_SAVE__ || null;
  const browserRaw = localStorage.getItem(KEY);
  const chosen = newer(browserRaw, nativeRaw);
  if(chosen) localStorage.setItem(KEY, chosen);

  document.body.classList.add('native-app');

  const post = payload => {
    try{
      window.webkit?.messageHandlers?.grove?.postMessage(payload);
    }catch(error){
      console.error('PomoLand native bridge error', error);
    }
  };

  window.GroveNative = {
    save(state){
      post({ action: 'save', state });
    },
    prepare(){
      post({ action: 'prepare' });
      return Promise.resolve();
    },
    liveDebug(){
      post({ action: 'liveDebug' });
    },
    liveTest(){
      post({ action: 'liveTest' });
    },
    liveEnd(){
      post({ action: 'liveEnd' });
    }
  };

  function formatDiagnostic(payload){
    const yes = value => value ? 'YES' : 'NO';
    const lines = [
      `Supported: ${yes(payload.supported)}`,
      `Live Activities enabled: ${yes(payload.enabled)}`,
      `ActivityKit active count: ${payload.activeCount ?? 0}`,
      `Last timer liveID: ${payload.lastLiveID || 'none'}`,
      `Status: ${payload.status || 'No status'}`
    ];
    if(payload.activeLiveIDs?.length){
      lines.push(`Active liveIDs: ${payload.activeLiveIDs.join(', ')}`);
    }
    if(payload.error){
      lines.push(`Error: ${payload.error}`);
    }
    return lines.join('\n');
  }

  window.__POMOLAND_LIVE_DIAGNOSTIC__ = payload => {
    window.__POMOLAND_LAST_LIVE_DIAGNOSTIC__ = payload;
    const output = document.getElementById('pomoland-live-output');
    if(output) output.textContent = formatDiagnostic(payload);
  };

  function installLiveDiagnosticUI(){
    const settings = document.getElementById('settings');
    if(!settings || document.getElementById('pomoland-live-diagnostics')) return;

    const block = document.createElement('section');
    block.id = 'pomoland-live-diagnostics';
    block.style.cssText = 'margin:18px 0;padding:14px;border:1px solid rgba(94,73,105,.2);border-radius:16px;background:rgba(255,255,255,.46);';
    block.innerHTML = `
      <div style="font-size:11px;font-weight:800;letter-spacing:.08em;margin-bottom:7px;">LIVE ACTIVITY DIAGNOSTICS</div>
      <p style="margin:0 0 10px;font-size:13px;line-height:1.35;">Temporary Build 39 tools. “Test Live Activity” bypasses the PomoLand timer and asks ActivityKit directly for a five-minute Live Activity.</p>
      <div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:10px;">
        <button type="button" id="pomoland-live-check" class="pill">Check status</button>
        <button type="button" id="pomoland-live-test" class="pill">Test Live Activity</button>
        <button type="button" id="pomoland-live-end" class="text-button">End test</button>
      </div>
      <pre id="pomoland-live-output" style="white-space:pre-wrap;font:12px/1.45 ui-monospace,SFMono-Regular,Menlo,monospace;margin:0;padding:10px;border-radius:12px;background:rgba(72,54,81,.07);">Not checked yet.</pre>
    `;

    const saveButton = document.getElementById('save-settings');
    if(saveButton) settings.insertBefore(block, saveButton);
    else settings.appendChild(block);

    document.getElementById('pomoland-live-check')?.addEventListener('click', () => window.GroveNative.liveDebug());
    document.getElementById('pomoland-live-test')?.addEventListener('click', () => window.GroveNative.liveTest());
    document.getElementById('pomoland-live-end')?.addEventListener('click', () => window.GroveNative.liveEnd());

    window.GroveNative.liveDebug();
  }

  const script = document.createElement('script');
  script.src = 'app.js';
  script.onload = () => {
    const raw = localStorage.getItem(KEY);
    const current = valid(raw);
    if(current) window.GroveNative.save(current);
    installLiveDiagnosticUI();
    window.dispatchEvent(new Event('grove-native-ready'));
  };
  document.body.appendChild(script);
})();
