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
    }
  };

  const script = document.createElement('script');
  script.src = 'app.js';
  script.onload = () => {
    const raw = localStorage.getItem(KEY);
    const current = valid(raw);
    if(current) window.GroveNative.save(current);
    window.dispatchEvent(new Event('grove-native-ready'));
  };
  document.body.appendChild(script);
})();
