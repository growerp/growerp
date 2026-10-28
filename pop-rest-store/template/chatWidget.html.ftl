<#-- Shared floating chat widget, included by both store.xml and website.xml.
     Requires screen context vars: productStoreId, productStore.
     The visible text comes from moqui.basic.LocalizedMessage so the widget follows the
     language the page is served in (/nl/, /th/, ...), see growerp data/GrowerpL10nData.xml. -->
<#function l key><#return ec.l10n.localize(key)></#function>
<style>
#growerp-chat-btn{position:fixed;right:20px;bottom:20px;z-index:2147483000;
  display:flex;align-items:center;gap:10px;cursor:pointer;
  background:#2962ff;color:#fff;border:none;border-radius:28px;
  height:56px;padding:0 16px;box-shadow:0 4px 14px rgba(0,0,0,.25);
  font-family:Arial,Helvetica,sans-serif;font-size:14px;line-height:1.2;
  max-width:56px;overflow:hidden;white-space:nowrap;
  transition:max-width .4s ease,border-radius .4s ease,background .2s ease}
#growerp-chat-btn svg{flex:0 0 auto;width:24px;height:24px;fill:#fff}
#growerp-chat-btn .growerp-chat-label{opacity:0;transition:opacity .3s ease .1s}
#growerp-chat-btn.growerp-expanded{max-width:260px;border-radius:14px}
#growerp-chat-btn.growerp-expanded .growerp-chat-label{opacity:1}
#growerp-chat-panel{position:fixed;box-sizing:border-box;right:20px;bottom:86px;z-index:2147483000;
  width:320px;max-width:calc(100vw - 40px);display:none;flex-direction:column;
  background:#fff;color:#222;border-radius:12px;overflow:hidden;
  box-shadow:0 8px 28px rgba(0,0,0,.3);font-family:Arial,Helvetica,sans-serif}
#growerp-chat-panel.growerp-open{display:flex}
#growerp-chat-panel .growerp-chat-head{background:#2962ff;color:#fff;
  padding:12px 14px;font-size:15px;font-weight:bold}
#growerp-chat-panel .growerp-chat-body{padding:14px;display:flex;flex-direction:column;gap:10px}
#growerp-chat-panel label{font-size:12px;color:#555}
#growerp-chat-panel input,#growerp-chat-panel textarea{
  width:100%;box-sizing:border-box;border:1px solid #ccc;border-radius:6px;
  padding:8px;font-size:14px;font-family:inherit;background:#fff;color:#222}
#growerp-chat-panel input::placeholder,#growerp-chat-panel textarea::placeholder{color:#888;opacity:1}
#growerp-chat-panel input:focus,#growerp-chat-panel textarea:focus{outline:none;border-color:#2962ff}
#growerp-chat-panel input:invalid,#growerp-chat-panel textarea:invalid{box-shadow:none}
#growerp-chat-panel textarea{resize:vertical;min-height:72px}
#growerp-chat-panel button.growerp-chat-send{background:#2962ff;color:#fff;border:none;
  border-radius:6px;padding:10px;font-size:14px;cursor:pointer}
#growerp-chat-panel button.growerp-chat-send:disabled{opacity:.6;cursor:default}
#growerp-chat-status{font-size:13px;min-height:18px}
#growerp-chat-status.growerp-err{color:#c62828}
#growerp-chat-status.growerp-ok{color:#2e7d32}
/* conversation (thread) mode */
#growerp-chat-thread{display:none;flex-direction:column;height:340px;
  max-height:calc(100vh - 180px)}
#growerp-chat-panel.growerp-mode-thread .growerp-chat-body{display:none}
#growerp-chat-panel.growerp-mode-thread #growerp-chat-thread{display:flex}
#growerp-chat-msgs{flex:1 1 auto;overflow-y:auto;padding:12px;
  display:flex;flex-direction:column;gap:8px;background:#f5f7fb}
#growerp-chat-msgs .growerp-msg{max-width:80%;padding:8px 10px;border-radius:12px;
  font-size:13px;line-height:1.35;word-wrap:break-word;white-space:pre-wrap}
#growerp-chat-msgs .growerp-msg .growerp-msg-meta{display:block;font-size:10px;
  opacity:.6;margin-top:3px}
#growerp-chat-msgs .growerp-mine{align-self:flex-end;background:#2962ff;color:#fff;
  border-bottom-right-radius:3px}
#growerp-chat-msgs .growerp-theirs{align-self:flex-start;background:#fff;color:#222;
  border:1px solid #e0e0e0;border-bottom-left-radius:3px}
#growerp-chat-compose{display:flex;gap:8px;padding:10px;border-top:1px solid #eee;
  align-items:flex-end}
#growerp-chat-compose textarea{flex:1 1 auto;min-height:38px;max-height:96px;
  box-sizing:border-box;border:1px solid #ccc;border-radius:8px;padding:8px;
  font-size:14px;font-family:inherit;resize:none;background:#fff;color:#222}
#growerp-chat-compose textarea::placeholder{color:#888;opacity:1}
#growerp-chat-compose textarea:focus{outline:none;border-color:#2962ff}
#growerp-chat-compose button{flex:0 0 auto;background:#2962ff;color:#fff;border:none;
  border-radius:8px;padding:0 16px;height:38px;font-size:14px;cursor:pointer}
#growerp-chat-compose button:disabled{opacity:.6;cursor:default}
#growerp-chat-panel .growerp-chat-head{display:flex;align-items:center;
  justify-content:space-between;gap:8px}
#growerp-chat-new{display:none;background:rgba(255,255,255,.2);color:#fff;
  border:none;border-radius:6px;padding:4px 8px;font-size:12px;cursor:pointer}
#growerp-chat-panel.growerp-mode-thread #growerp-chat-new{display:inline-block}
#growerp-chat-msgs .growerp-divider{align-self:center;font-size:11px;color:#888;
  margin:6px 0}
#growerp-chat-msgs .growerp-optimistic{opacity:.55}
/* agent replies are markdown, rendered by renderMd() */
#growerp-chat-msgs .growerp-md{white-space:normal}
#growerp-chat-msgs .growerp-md p{margin:0 0 6px}
#growerp-chat-msgs .growerp-md ul,#growerp-chat-msgs .growerp-md ol{margin:0 0 6px;padding-left:18px}
#growerp-chat-msgs .growerp-md ul{list-style:disc}
#growerp-chat-msgs .growerp-md ol{list-style:decimal}
#growerp-chat-msgs .growerp-md code{background:#eef1f6;border-radius:3px;padding:0 3px;
  font-family:Consolas,monospace;font-size:12px}
#growerp-chat-msgs .growerp-md pre{background:#eef1f6;border-radius:6px;padding:6px 8px;
  margin:0 0 6px;overflow-x:auto;white-space:pre}
#growerp-chat-msgs .growerp-md pre code{background:none;padding:0}
#growerp-chat-msgs .growerp-md a{color:#2962ff}
/* agent working: three bouncing dots */
#growerp-chat-msgs .growerp-typing{display:flex;gap:4px;padding:10px 12px}
#growerp-chat-msgs .growerp-typing span{width:6px;height:6px;border-radius:50%;
  background:#999;animation:growerp-bounce 1.2s infinite ease-in-out}
#growerp-chat-msgs .growerp-typing span:nth-child(2){animation-delay:.2s}
#growerp-chat-msgs .growerp-typing span:nth-child(3){animation-delay:.4s}
@keyframes growerp-bounce{0%,60%,100%{transform:translateY(0);opacity:.4}
  30%{transform:translateY(-4px);opacity:1}}
/* resize grip, top-left because the panel is anchored bottom-right */
#growerp-chat-grip{position:absolute;left:4px;top:4px;width:22px;height:22px;cursor:nwse-resize;
  z-index:1;touch-action:none;opacity:.85;border-radius:4px}
#growerp-chat-grip svg{width:22px;height:22px;fill:#fff;display:block}
#growerp-chat-grip:hover{opacity:1;background:rgba(255,255,255,.2)}
#growerp-chat-panel .growerp-chat-head{padding-left:32px}
@media (max-width:480px){#growerp-chat-panel .growerp-chat-head{padding-left:14px}}
@media (max-width:480px){#growerp-chat-grip{display:none}}
</style>
<button id="growerp-chat-btn" type="button" aria-label="${l('GrowerpWebsiteChatAsk')}">
  <svg viewBox="0 0 24 24"><path d="M20 2H4a2 2 0 0 0-2 2v18l4-4h14a2 2 0 0 0 2-2V4a2 2 0 0 0-2-2zm-2 9H6V9h12v2zm0-3H6V6h12v2z"/></svg>
  <span class="growerp-chat-label">${l('GrowerpWebsiteChatPrompt')}<br>${l('GrowerpWebsiteChatPromptSub')}</span>
</button>
<div id="growerp-chat-panel" role="dialog" aria-label="${l('GrowerpWebsiteChatAsk')}">
  <div id="growerp-chat-grip" aria-hidden="true" title="Drag to resize">
    <svg viewBox="0 0 24 24"><path d="M5 5h7v2H8.41l7.59 7.59V11h2v7h-7v-2h3.59L7 8.41V12H5z"/></svg>
  </div>
  <div class="growerp-chat-head">
    <span id="growerp-chat-title">${l('GrowerpWebsiteChatTitle')}</span>
    <button id="growerp-chat-new" type="button">${l('GrowerpWebsiteChatNewQuestion')}</button>
  </div>
  <!-- start form: shown until a conversation has been started -->
  <div class="growerp-chat-body">
    <div>
      <label for="growerp-chat-email">${l('GrowerpWebsiteChatEmailLabel')}</label>
      <input id="growerp-chat-email" type="email" required placeholder="you@example.com"/>
    </div>
    <div>
      <label for="growerp-chat-question">${l('GrowerpWebsiteChatQuestionLabel')}</label>
      <textarea id="growerp-chat-question" placeholder="${l('GrowerpWebsiteChatQuestionPlaceholder')}"></textarea>
    </div>
    <div id="growerp-chat-status"></div>
    <button class="growerp-chat-send" type="button">${l('GrowerpWebsiteChatSend')}</button>
  </div>
  <!-- conversation thread: shown once a room exists -->
  <div id="growerp-chat-thread">
    <div id="growerp-chat-msgs"></div>
    <div id="growerp-chat-compose">
      <textarea id="growerp-chat-input" rows="1" placeholder="${l('GrowerpWebsiteChatMessagePlaceholder')}"></textarea>
      <button id="growerp-chat-post" type="button">${l('GrowerpWebsiteChatSend')}</button>
    </div>
  </div>
</div>
<script>
(function(){
  var productStoreId = "${productStoreId}";
  var companyName = "${(productStore.storeName)!'Support'}";
  // the visible strings, localized server side; {name} is filled in below
  var T = {
    title: "${l('GrowerpWebsiteChatTitle')?js_string}",
    chatWith: "${l('GrowerpWebsiteChatWith')?js_string}",
    expired: "${l('GrowerpWebsiteChatExpired')?js_string}",
    invalidEmail: "${l('GrowerpWebsiteChatInvalidEmail')?js_string}",
    noQuestion: "${l('GrowerpWebsiteChatNoQuestion')?js_string}",
    failed: "${l('GrowerpWebsiteChatError')?js_string}",
    newDivider: "${l('GrowerpWebsiteChatDivider')?js_string}",
    close: "${l('GrowerpWebsiteChatClose')?js_string}"
  };
  var apiBase = window.location.origin + '/rest/s1/growerp/100/WebsiteChat';
  var storeKey  = 'growerp_chat_' + productStoreId;
  var openKey   = 'growerp_chat_open_' + productStoreId;
  var emailKey  = 'growerp_chat_email_' + productStoreId;   // cookie + localStorage name
  var sizeKey   = 'growerp_chat_size_' + productStoreId;

  var btn = document.getElementById('growerp-chat-btn');
  var panel = document.getElementById('growerp-chat-panel');
  var titleEl = document.getElementById('growerp-chat-title');
  var newBtn = document.getElementById('growerp-chat-new');
  var emailEl = document.getElementById('growerp-chat-email');
  var questionEl = document.getElementById('growerp-chat-question');
  var statusEl = document.getElementById('growerp-chat-status');
  var sendBtn = panel.querySelector('.growerp-chat-send');
  var msgsEl = document.getElementById('growerp-chat-msgs');
  var inputEl = document.getElementById('growerp-chat-input');
  var postBtn = document.getElementById('growerp-chat-post');
  var labelEl = btn.querySelector('.growerp-chat-label');
  var threadEl = document.getElementById('growerp-chat-thread');
  var gripEl = document.getElementById('growerp-chat-grip');
  var labelClosed = labelEl.innerHTML;   // "Question?…" prompt while panel is shut

  var session = loadSession();   // {chatRoomId, visitorToken, visitorUserId} or null
  var seenIds = {};
  var pollTimer = null;
  var agentActive = false;   // from the last poll: an agent answers in this room
  var typingEl = null, typingTimer = null;

  // --- persistence helpers (cookie for email so it survives, localStorage for rest) ---
  function setCookie(name, value, days){
    var d = new Date(); d.setTime(d.getTime() + days*864e5);
    document.cookie = name + '=' + encodeURIComponent(value) +
      ';expires=' + d.toUTCString() + ';path=/;SameSite=Lax';
  }
  function getCookie(name){
    var m = document.cookie.match('(?:^|; )' +
      name.replace(/([.$?*|{}()\[\]\\\/\+^])/g,'\\$1') + '=([^;]*)');
    return m ? decodeURIComponent(m[1]) : '';
  }
  function getEmail(){
    var c = getCookie(emailKey);
    if (c) return c;
    try { return localStorage.getItem(emailKey) || ''; } catch(e){ return ''; }
  }
  function setEmail(e){
    setCookie(emailKey, e, 365);
    try { localStorage.setItem(emailKey, e); } catch(err){}
  }
  function loadSession(){
    try { return JSON.parse(localStorage.getItem(storeKey)) || null; }
    catch(e){ return null; }
  }
  function saveSession(s){
    session = s;
    try { localStorage.setItem(storeKey, JSON.stringify(s)); } catch(e){}
  }
  function rememberOpen(isOpen){
    try { localStorage.setItem(openKey, isOpen ? '1' : '0'); } catch(e){}
  }
  function wasOpen(){
    try { return localStorage.getItem(openKey) === '1'; } catch(e){ return false; }
  }

  // prefill a returning visitor's email
  emailEl.value = getEmail();

  // one-time attention animation only for first-time, closed visitors
  if (!wasOpen()) setTimeout(function(){
    if (!panel.classList.contains('growerp-open')) btn.classList.add('growerp-expanded');
    setTimeout(function(){
      if (!panel.classList.contains('growerp-open')) btn.classList.remove('growerp-expanded');
    }, 2000);
  }, 3000);

  btn.addEventListener('mouseenter', function(){ btn.classList.add('growerp-expanded'); });
  btn.addEventListener('mouseleave', function(){
    if (!panel.classList.contains('growerp-open')) btn.classList.remove('growerp-expanded');
  });

  function setStatus(msg, kind){
    statusEl.textContent = msg || '';
    statusEl.className = kind ? ('growerp-' + kind) : '';
  }
  function validEmail(v){ return /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(v); }

  // switch the panel into conversation mode (thread + compose box)
  function showThread(){
    panel.classList.add('growerp-mode-thread');
    titleEl.textContent = T.chatWith.replace('{name}', companyName);
  }

  function escapeHtml(s){
    return (s || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
  }

  // small markdown subset for agent replies; input is escaped first so no html gets through
  function inlineMd(s){
    return s
      .replace(/`([^`]+)`/g, '<code>$1</code>')
      .replace(/\*\*([^*]+)\*\*/g, '<b>$1</b>')
      .replace(/(^|[^*])\*([^*\s][^*]*)\*/g, '$1<i>$2</i>')
      .replace(/\[([^\]]+)\]\((https?:\/\/[^\s)"]+)\)/g,
        '<a href="$2" target="_blank" rel="noopener">$1</a>')
      .replace(/(^|[\s(])(https?:\/\/[^\s<)"]+)/g,
        '$1<a href="$2" target="_blank" rel="noopener">$2</a>');
  }
  function renderMd(text){
    var parts = escapeHtml(text).split(/```[^\n]*\n?/);
    var out = '';
    for (var i = 0; i < parts.length; i++){
      if (i % 2){ out += '<pre><code>' + parts[i].replace(/\n$/, '') + '</code></pre>'; continue; }
      var lines = parts[i].split('\n'), list = null, para = [];
      var flush = function(){
        if (para.length){ out += '<p>' + para.join('<br>') + '</p>'; para = []; }
      };
      var closeList = function(){ if (list){ out += '</' + list + '>'; list = null; } };
      lines.forEach(function(line){
        var ul = /^\s*[-*]\s+(.*)/.exec(line), ol = /^\s*\d+[.)]\s+(.*)/.exec(line);
        var h = /^#+\s+(.*)/.exec(line);
        if (ul || ol){
          flush();
          var tag = ul ? 'ul' : 'ol';
          if (list !== tag){ closeList(); out += '<' + tag + '>'; list = tag; }
          out += '<li>' + inlineMd((ul || ol)[1]) + '</li>';
        } else if (h){
          flush(); closeList(); out += '<p><b>' + inlineMd(h[1]) + '</b></p>';
        } else if (!line.trim()){
          flush(); closeList();
        } else {
          closeList(); para.push(inlineMd(line));
        }
      });
      flush(); closeList();
    }
    return out;
  }

  // agent working indicator, shown after the visitor sends until a reply comes in
  function showTyping(){
    hideTyping();
    typingEl = document.createElement('div');
    typingEl.className = 'growerp-msg growerp-theirs growerp-typing';
    typingEl.innerHTML = '<span></span><span></span><span></span>';
    msgsEl.appendChild(typingEl);
    msgsEl.scrollTop = msgsEl.scrollHeight;
    typingTimer = setTimeout(hideTyping, 90000);   // agent failed or handed off
    restartPolling(1500);
  }
  function hideTyping(){
    if (typingTimer){ clearTimeout(typingTimer); typingTimer = null; }
    if (!typingEl) return;
    typingEl.parentNode && typingEl.parentNode.removeChild(typingEl);
    typingEl = null;
    restartPolling(4000);
  }

  function appendMessage(m){
    if (!m || seenIds[m.chatMessageId]) return;
    seenIds[m.chatMessageId] = true;
    var mine = session && String(m.fromUserId) === String(session.visitorUserId);
    var div = document.createElement('div');
    div.className = 'growerp-msg ' + (mine ? 'growerp-mine' : 'growerp-theirs growerp-md');
    var who = mine ? 'You' : (m.fromUserFullName || companyName);
    div.innerHTML = (mine ? escapeHtml(m.content) : renderMd(m.content)) +
      '<span class="growerp-msg-meta">' + escapeHtml(who) +
      (m.creationDate ? ' · ' + escapeHtml(m.creationDate) : '') + '</span>';
    if (!mine) hideTyping();
    // keep the dots below the newest message
    if (typingEl) msgsEl.insertBefore(div, typingEl); else msgsEl.appendChild(div);
    msgsEl.scrollTop = msgsEl.scrollHeight;
  }
  function appendDivider(text){
    var div = document.createElement('div');
    div.className = 'growerp-divider';
    div.textContent = text;
    msgsEl.appendChild(div);
    msgsEl.scrollTop = msgsEl.scrollHeight;
  }
  // show the visitor's own message instantly (as "You"); replaced by the polled copy
  function appendOptimistic(content){
    var div = document.createElement('div');
    div.className = 'growerp-msg growerp-mine growerp-optimistic';
    div.innerHTML = escapeHtml(content) +
      '<span class="growerp-msg-meta">You · sending…</span>';
    if (typingEl) msgsEl.insertBefore(div, typingEl); else msgsEl.appendChild(div);
    msgsEl.scrollTop = msgsEl.scrollHeight;
  }
  function clearOptimistic(){
    var nodes = msgsEl.querySelectorAll('.growerp-optimistic');
    for (var i = 0; i < nodes.length; i++) nodes[i].parentNode.removeChild(nodes[i]);
  }

  function resetToForm(){
    hideTyping();
    stopPolling();
    saveSession(null);
    try { localStorage.removeItem(storeKey); } catch(e){}
    seenIds = {};
    msgsEl.innerHTML = '';
    panel.classList.remove('growerp-mode-thread');
    titleEl.textContent = T.title;
    questionEl.value = '';
    sendBtn.disabled = false;
    setStatus(T.expired, 'err');
  }
  function fetchMessages(){
    if (!session || !session.chatRoomId) return;
    var url = apiBase + '/messages?productStoreId=' + encodeURIComponent(productStoreId) +
      '&chatRoomId=' + encodeURIComponent(session.chatRoomId) +
      '&visitorToken=' + encodeURIComponent(session.visitorToken);
    fetch(url, { headers: { 'Accept': 'application/json' } })
      .then(function(r){
        if (!r.ok) { resetToForm(); return null; }
        return r.json();
      })
      .then(function(d){
        if (!d) return;
        agentActive = !!d.agentActive;
        if (!agentActive) hideTyping();
        // once the server thread is in, drop any pending optimistic bubbles
        if (d.chatMessages && d.chatMessages.length) clearOptimistic();
        (d.chatMessages || []).forEach(appendMessage);
      }).catch(function(){ resetToForm(); });
  }
  function startPolling(){
    if (pollTimer || !session || !session.chatRoomId) return;
    fetchMessages();
    pollTimer = setInterval(fetchMessages, typingEl ? 1500 : 4000);
  }
  // change the poll rate, only while polling is on (panel open, room active)
  function restartPolling(ms){
    if (!pollTimer) return;
    clearInterval(pollTimer);
    pollTimer = setInterval(fetchMessages, ms);
  }
  function stopPolling(){
    if (pollTimer){ clearInterval(pollTimer); pollTimer = null; }
  }

  // open a brand-new chatroom: first message is the question
  function startRoom(email, question, onErr){
    fetch(apiBase, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ productStoreId: productStoreId, email: email, question: question })
    }).then(function(r){
      if (!r.ok) throw new Error('http ' + r.status);
      return r.json();
    }).then(function(d){
      setEmail(email);
      saveSession({ chatRoomId: d.chatRoomId, visitorToken: d.visitorToken,
        visitorUserId: d.visitorUserId });
      showThread();
      sendBtn.disabled = false; postBtn.disabled = false;
      startPolling();   // immediately pulls in the just-sent question (replaces optimistic)
      if (d.agentActive !== false) showTyping();   // the first poll hides it when no agent
    }).catch(function(){ if (onErr) onErr(); });
  }

  // ----- first-contact form (email + question) -----
  sendBtn.addEventListener('click', function(){
    var email = (emailEl.value || '').trim();
    var question = (questionEl.value || '').trim();
    if (!validEmail(email)){ setStatus(T.invalidEmail, 'err'); emailEl.focus(); return; }
    if (!question){ setStatus(T.noQuestion, 'err'); questionEl.focus(); return; }
    setStatus('', '');
    sendBtn.disabled = true;
    // show the conversation with the question already in it, then send
    showThread();
    appendOptimistic(question);
    questionEl.value = '';
    startRoom(email, question, function(){
      // failure: drop the pending bubble, restore the form + typed text, allow retry
      clearOptimistic();
      panel.classList.remove('growerp-mode-thread');
      questionEl.value = question;
      setStatus(T.failed, 'err');
      sendBtn.disabled = false;
    });
  });

  // ----- compose box: follow-up in current room, or first msg of a new room -----
  function sendCompose(){
    var content = (inputEl.value || '').trim();
    if (!content) return;
    postBtn.disabled = true;
    appendOptimistic(content);
    inputEl.value = '';
    if (session && session.chatRoomId){
      // follow-up message in the existing room
      fetch(apiBase + '/messages', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ productStoreId: productStoreId, chatRoomId: session.chatRoomId,
          visitorToken: session.visitorToken, content: content })
      }).then(function(r){
        if (!r.ok) throw new Error('http ' + r.status);
        return r.json();
      }).then(function(d){
        postBtn.disabled = false;
        clearOptimistic();
        if (d.chatMessage) appendMessage(d.chatMessage);
        if (agentActive) showTyping();
        inputEl.focus();
      }).catch(function(){
        clearOptimistic(); inputEl.value = content; postBtn.disabled = false;
      });
    } else {
      // no active room (after "New question") -> start a fresh room with this message
      startRoom(getEmail(), content, function(){
        clearOptimistic(); inputEl.value = content; postBtn.disabled = false;
      });
      inputEl.focus();
    }
  }
  postBtn.addEventListener('click', sendCompose);
  inputEl.addEventListener('keydown', function(e){
    if (e.key === 'Enter' && !e.shiftKey){ e.preventDefault(); sendCompose(); }
  });

  // ----- "Ask another question": keep old messages, route next send to a NEW room -----
  newBtn.addEventListener('click', function(){
    hideTyping();
    stopPolling();
    appendDivider(T.newDivider);
    saveSession({ chatRoomId: null });   // keep email cookie; next send starts a new room
    inputEl.focus();
  });

  function openPanel(remember){
    panel.classList.add('growerp-open');
    btn.classList.add('growerp-expanded');
    labelEl.textContent = T.close;
    if (remember !== false) rememberOpen(true);
    if (session && session.chatRoomId){ startPolling(); inputEl.focus(); }
    else if (panel.classList.contains('growerp-mode-thread')) inputEl.focus();
    else emailEl.focus();
  }
  function closePanel(){
    panel.classList.remove('growerp-open');
    btn.classList.remove('growerp-expanded');
    labelEl.innerHTML = labelClosed;
    stopPolling();
    rememberOpen(false);
  }

  // ----- resize by dragging the top-left grip; the size is remembered -----
  function applySize(w, h){
    w = Math.max(320, Math.min(w, window.innerWidth - 40));
    h = Math.max(300, Math.min(h, window.innerHeight - 180));
    panel.style.width = w + 'px';
    threadEl.style.height = h + 'px';
    return { w: w, h: h };
  }
  try {
    var saved = JSON.parse(localStorage.getItem(sizeKey));
    if (saved && window.innerWidth > 480) applySize(saved.w, saved.h);
  } catch(e){}
  gripEl.addEventListener('pointerdown', function(e){
    e.preventDefault();
    gripEl.setPointerCapture(e.pointerId);
    var x0 = e.clientX, y0 = e.clientY;
    var w0 = panel.offsetWidth, h0 = threadEl.offsetHeight || 340;
    var size = null;
    function move(ev){ size = applySize(w0 + x0 - ev.clientX, h0 + y0 - ev.clientY); }
    function up(){
      gripEl.removeEventListener('pointermove', move);
      gripEl.removeEventListener('pointerup', up);
      if (size) try { localStorage.setItem(sizeKey, JSON.stringify(size)); } catch(err){}
    }
    gripEl.addEventListener('pointermove', move);
    gripEl.addEventListener('pointerup', up);
  });

  // restore on load: active room -> thread; else known email -> thread compose; else form
  if (session && session.chatRoomId) showThread();
  else if (getEmail()) showThread();
  // re-open the panel if the visitor left it open last time
  if (wasOpen()) openPanel(false);

  btn.addEventListener('click', function(){
    if (panel.classList.contains('growerp-open')) closePanel();
    else openPanel();
  });
})();
</script>
