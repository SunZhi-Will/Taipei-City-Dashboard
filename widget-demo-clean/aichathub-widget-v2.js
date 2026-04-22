"use strict";(()=>{var k=class{constructor(t){this.config=t,console.log("[ApiService] \u69CB\u9020\u51FD\u6578\uFF0Cconfig.baseUrl:",t.baseUrl),console.log("[ApiService] config.baseUrl \u985E\u578B:",typeof t.baseUrl),console.log("[ApiService] window.location.origin:",window.location.origin),!t.baseUrl||t.baseUrl===""?(this.baseUrl=window.location.origin,console.log("[ApiService] config.baseUrl \u70BA\u7A7A\uFF0C\u4F7F\u7528 window.location.origin:",this.baseUrl)):(this.baseUrl=t.baseUrl.replace(/\/$/,""),console.log("[ApiService] \u4F7F\u7528 config.baseUrl:",this.baseUrl))}async sendMessage(t,a){let e={"Content-Type":"application/json"};this.config.apiKey&&(e["X-API-Key"]=this.config.apiKey);let o=`${this.baseUrl}/api/chat`;console.log("[ApiService] \u767C\u9001\u8ACB\u6C42\u5230:",o),console.log("[ApiService] this.baseUrl:",this.baseUrl),console.log("[ApiService] \u8ACB\u6C42 body:",{chatBotId:this.config.chatBotId||this.config.projectId,conversationHistoryId:a,message:t,enableRag:this.config.enableRag!==!1});let i=await fetch(o,{method:"POST",headers:e,body:JSON.stringify({chatBotId:this.config.chatBotId||this.config.projectId,conversationHistoryId:a,message:t,enableRag:this.config.enableRag!==!1})});if(!i.ok)throw new Error("API \u8ACB\u6C42\u5931\u6557");return await i.json()}async submitFeedback(t,a,e){let o={"Content-Type":"application/json"};if(this.config.apiKey&&(o["X-API-Key"]=this.config.apiKey),!(await fetch(`${this.baseUrl}/api/chat/message/${t}/feedback`,{method:"POST",headers:o,body:JSON.stringify({feedbackType:a,feedbackData:e||null})})).ok)throw new Error("\u53CD\u994B\u63D0\u4EA4\u5931\u6557")}sendAnalyticsEvent(t,a){if(!this.config.enableAnalytics)return;let e=JSON.parse(localStorage.getItem("aiChatHubEvents")||"[]");e.push({event:t,data:a,timestamp:Date.now(),projectId:this.config.projectId}),e.length>100&&e.shift(),localStorage.setItem("aiChatHubEvents",JSON.stringify(e))}async getSuggestedTags(t,a){try{let e={"Content-Type":"application/json"};this.config.apiKey&&(e["X-API-Key"]=this.config.apiKey);let o=await fetch(`${this.baseUrl}/api/chat/suggested-tags`,{method:"POST",headers:e,body:JSON.stringify({chatBotId:this.config.chatBotId||this.config.projectId,conversationHistoryId:t,currentInput:a||""})});if(!o.ok)throw new Error("\u7372\u53D6\u5EFA\u8B70\u6A19\u7C64\u5931\u6557");return(await o.json()).tags||[]}catch(e){return console.error("[ApiService] \u7372\u53D6\u5EFA\u8B70\u6A19\u7C64\u5931\u6557:",e),[]}}};var E=class{constructor(t){this.storageKey=`aiChatHub_${t}_history`}saveMessages(t){try{localStorage.setItem(this.storageKey,JSON.stringify(t))}catch(a){console.warn("Failed to save messages to localStorage:",a)}}loadMessages(){try{let t=localStorage.getItem(this.storageKey);return t?JSON.parse(t):[]}catch(t){return console.warn("Failed to load messages from localStorage:",t),[]}}clearMessages(){localStorage.removeItem(this.storageKey)}};function c(d,t,a){let e=document.createElement(d);return t&&(e.className=t),a&&(e.textContent=a),e}function x(d){let t=document.createElement("div");return t.textContent=d,t.innerHTML}function G(d){try{let t=document.createElement("template");return t.innerHTML=d,t.content.querySelectorAll("script,iframe,object,embed,style").forEach(a=>a.remove()),t.content.querySelectorAll("*").forEach(a=>{Array.from(a.attributes).forEach(e=>{let o=e.name.toLowerCase(),i=String(e.value||"").trim().toLowerCase();(o.startsWith("on")||((o==="href"||o==="src")&&(i.startsWith("javascript:")||i.startsWith("data:text/html"))))&&a.removeAttribute(e.name)})}),t.innerHTML}catch(t){return x(d)}}var I=class{constructor(t){console.log("[Launcher] \u958B\u59CB\u521D\u59CB\u5316"),this.config=t,this.element=this.createLauncher(),console.log("[Launcher] \u521D\u59CB\u5316\u5B8C\u6210\uFF0Celement:",this.element)}createLauncher(){console.log("[Launcher] \u5275\u5EFA\u6309\u9215\u5143\u7D20");let t=c("button","aichathub-launcher");return t.setAttribute("data-position",this.config.position||"bottom-right"),t.setAttribute("aria-label","開啟聊天助理"),t.setAttribute("aria-expanded","false"),t.setAttribute("aria-haspopup","dialog"),t.innerHTML=`
      <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="currentColor" viewBox="0 0 16 16">
        <path d="M2.678 11.894a1 1 0 0 1 .287.801 11 11 0 0 1-.398 2c1.395-.323 2.247-.697 2.634-.893a1 1 0 0 1 .71-.074A8 8 0 0 0 8 14c3.996 0 7-2.807 7-6s-3.004-6-7-6-7 2.808-7 6c0 1.468.617 2.83 1.678 3.894"/>
        <path d="M4.5 9a.5.5 0 0 1 .5-.5h6a.5.5 0 0 1 0 1h-6a.5.5 0 0 1-.5-.5M4 6.5a.5.5 0 0 1 .5-.5h7a.5.5 0 0 1 0 1h-7a.5.5 0 0 1-.5-.5"/>
      </svg>
    `,console.log("[Launcher] \u6309\u9215\u5143\u7D20\u5275\u5EFA\u5B8C\u6210\uFF0CclassName:",t.className),t}getElement(){return this.element}show(){console.log("[Launcher] show - \u986F\u793A\u6309\u9215"),this.element.classList.remove("hidden"),this.element.setAttribute("aria-expanded","false"),console.log("[Launcher] show - classList:",this.element.classList.toString())}hide(){console.log("[Launcher] hide - \u96B1\u85CF\u6309\u9215"),this.element.classList.add("hidden"),this.element.setAttribute("aria-expanded","true"),console.log("[Launcher] hide - classList:",this.element.classList.toString())}onClick(t){console.log("[Launcher] onClick - \u8A2D\u7F6E\u9EDE\u64CA\u4E8B\u4EF6\u76E3\u807D\u5668"),this.element.addEventListener("click",()=>{console.log("[Launcher] onClick - \u6309\u9215\u88AB\u9EDE\u64CA\uFF01\u8ABF\u7528 callback"),t()}),console.log("[Launcher] onClick - \u4E8B\u4EF6\u76E3\u807D\u5668\u8A2D\u7F6E\u5B8C\u6210")}};var L=class{static getOverlayTheme(t){let e=(t||document).querySelector(".aichathub-panel"),i=((e?getComputedStyle(e).backgroundColor:"rgb(248, 250, 252)").match(/\d+/g)||["248","250","252"]).slice(0,3).map(Number),n=(.299*i[0]+.587*i[1]+.114*i[2])/255<.52;return{dark:n,surface:n?"#18181b":"white",border:n?"rgba(255,255,255,0.16)":"#e4e4e7",text:n?"#f4f4f5":"#18181b",textMuted:n?"#a1a1aa":"#71717a",hover:n?"rgba(255,255,255,0.1)":"#f4f4f5"}}static initializeMap(t,a,e){let i=(e||document).getElementById(t);if(console.log("[Map Init] \u67E5\u627E\u5730\u5716\u5143\u7D20:",t,"\u627E\u5230:",!!i),!i){console.error("[Map Init] \u627E\u4E0D\u5230\u5730\u5716\u5143\u7D20:",t);return}let s=window.L;if(!s&&window.parent&&window.parent!==window)try{s=window.parent.L,console.log("[Map Init] \u5F9E\u7236\u9801\u9762\u7372\u53D6 Leaflet")}catch{console.log("[Map Init] \u7121\u6CD5\u5F9E\u7236\u9801\u9762\u7372\u53D6 Leaflet")}if(!s){console.error("[Map Init] Leaflet \u5EAB\u672A\u8F09\u5165");return}console.log("[Map Init] Leaflet \u5DF2\u8F09\u5165\uFF0C\u958B\u59CB\u521D\u59CB\u5316\u5730\u5716");try{let n=0,l=0;a.forEach(h=>{n+=h.lat,l+=h.lng}),n/=a.length,l/=a.length;let r=s.map(i,{center:[n,l],zoom:a.length===1?10:4,zoomControl:!0,scrollWheelZoom:!0});i._leaflet_map=r,s.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",{attribution:"\xA9 OpenStreetMap",maxZoom:18,minZoom:2}).addTo(r);let p=[];if(a.forEach(h=>{let m=s.marker([h.lat,h.lng]).addTo(r),g=`<div style="min-width: 200px; padding: 8px;"><div style="font-weight: 600; font-size: 14px; margin-bottom: 6px; color: #18181b;">${x(h.name)}</div>`;h.englishName&&(g+=`<div style="font-size: 12px; color: #71717a; margin-bottom: 6px;">${x(h.englishName)}</div>`),h.description&&(g+=`<div style="font-size: 12px; color: #52525b;">${x(h.description)}</div>`),g+="</div>",m.bindPopup(g),p.push(m)}),a.length>1){let h=s.featureGroup(p);r.fitBounds(h.getBounds().pad(.1))}}catch(n){console.error("\u5730\u5716\u521D\u59CB\u5316\u5931\u6557:",n)}}static getModalTarget(){try{if(window.self!==window.top&&window.parent&&window.parent.document){console.log("[Modal] \u6AA2\u6E2C\u5230 iframe \u74B0\u5883\uFF0C\u5617\u8A66\u4F7F\u7528\u7236\u9801\u9762 body");try{let t=window.parent.document.body;if(t)return console.log("[Modal] \u6210\u529F\u8A2A\u554F\u7236\u9801\u9762 body"),t}catch{console.log("[Modal] \u7121\u6CD5\u8A2A\u554F\u7236\u9801\u9762 body\uFF08\u53EF\u80FD\u662F\u8DE8\u57DF\u9650\u5236\uFF09\uFF0C\u4F7F\u7528\u7576\u524D iframe \u7684 body")}}}catch(t){console.log("[Modal] iframe \u6AA2\u6E2C\u5931\u6557\uFF0C\u4F7F\u7528\u7576\u524D body",t)}return document.body}static expandMap(t){console.log("[Map Expand] \u5C55\u958B\u5730\u5716\uFF0C\u5730\u9EDE\u6578\u91CF:",t.length);let a=this.getModalTarget(),e=a.ownerDocument||document;console.log("[Map Expand] \u4F7F\u7528\u7684 document:",e===document?"\u7576\u524D iframe":"\u7236\u9801\u9762");let o=e.createElement("div");o.style.cssText=`
      position: fixed !important;
      top: 0 !important;
      left: 0 !important;
      right: 0 !important;
      bottom: 0 !important;
      background: rgba(0, 0, 0, 0.95) !important;
      z-index: 2147483647 !important;
      display: flex !important;
      align-items: center !important;
      justify-content: center !important;
      padding: 20px !important;
      margin: 0 !important;
    `;let i=this.getOverlayTheme(e),s=e.createElement("div");s.style.cssText=`
      width: 100%;
      max-width: 1400px;
      height: 90vh;
      background: ${i.surface};
      border: 1px solid ${i.border};
      border-radius: 16px;
      padding: 0;
      position: relative;
      overflow: hidden;
      box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
    `;let n=e.createElement("button");n.innerHTML=`
      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" viewBox="0 0 16 16">
        <path d="M2.146 2.854a.5.5 0 1 1 .708-.708L8 7.293l5.146-5.147a.5.5 0 0 1 .708.708L8.707 8l5.147 5.146a.5.5 0 0 1-.708.708L8 8.707l-5.146 5.147a.5.5 0 0 1-.708-.708L7.293 8z"/>
      </svg>
    `,n.style.cssText=`
      position: absolute;
      top: 16px;
      right: 16px;
      background: ${i.surface};
      border: 1px solid ${i.border};
      color: ${i.textMuted};
      cursor: pointer;
      width: 40px;
      height: 40px;
      border-radius: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      transition: all 0.2s;
      z-index: 1001;
      box-shadow: 0 4px 6px rgba(0,0,0,0.1);
    `;let l=()=>{console.log("[Map Expand] \u95DC\u9589\u5730\u5716\u6A21\u614B\u8996\u7A97"),a.removeChild(o)};n.onmouseenter=()=>{n.style.background=i.hover,n.style.color=i.text},n.onmouseleave=()=>{n.style.background=i.surface,n.style.color=i.textMuted},n.onclick=l;let r="expanded-map-"+Date.now(),p=e.createElement("div");p.id=r,p.style.cssText="width: 100%; height: 100%; border-radius: 16px; overflow: hidden;",s.appendChild(p),s.appendChild(n),o.appendChild(s),a.appendChild(o),console.log("[Map Expand] \u6A21\u614B\u8996\u7A97\u5DF2\u52A0\u5165 DOM\uFF0C\u5730\u5716\u5BB9\u5668 ID:",r),console.log("[Map Expand] \u5730\u5716\u5BB9\u5668\u5143\u7D20:",e.getElementById(r)),setTimeout(()=>{console.log("[Map Expand] \u958B\u59CB\u521D\u59CB\u5316\u5730\u5716..."),this.initializeMap(r,t,e),setTimeout(()=>{let h=e.getElementById(r);if(h&&window.L){let m=h._leaflet_map;m&&(m.invalidateSize(),console.log("[Map Expand] \u5730\u5716\u5927\u5C0F\u5DF2\u91CD\u65B0\u8A08\u7B97"))}},300)},200),o.onclick=h=>{h.target===o&&a.removeChild(o)}}};var S=class{static getOverlayTheme(t){let e=(t||document).querySelector(".aichathub-panel"),i=((e?getComputedStyle(e).backgroundColor:"rgb(248, 250, 252)").match(/\d+/g)||["248","250","252"]).slice(0,3).map(Number),n=(.299*i[0]+.587*i[1]+.114*i[2])/255<.52;return{dark:n,surface:n?"#18181b":"white",border:n?"rgba(255,255,255,0.16)":"#e4e4e7",text:n?"#f4f4f5":"#18181b",textMuted:n?"#a1a1aa":"#71717a",hover:n?"rgba(255,255,255,0.1)":"#f4f4f5"}}static getModalTarget(){try{if(window.self!==window.top&&window.parent&&window.parent.document){console.log("[Modal] \u6AA2\u6E2C\u5230 iframe \u74B0\u5883\uFF0C\u5617\u8A66\u4F7F\u7528\u7236\u9801\u9762 body");try{let t=window.parent.document.body;if(t)return console.log("[Modal] \u6210\u529F\u8A2A\u554F\u7236\u9801\u9762 body"),t}catch{console.log("[Modal] \u7121\u6CD5\u8A2A\u554F\u7236\u9801\u9762 body\uFF08\u53EF\u80FD\u662F\u8DE8\u57DF\u9650\u5236\uFF09\uFF0C\u4F7F\u7528\u7576\u524D iframe \u7684 body")}}}catch(t){console.log("[Modal] iframe \u6AA2\u6E2C\u5931\u6557\uFF0C\u4F7F\u7528\u7576\u524D body",t)}return document.body}static expandChart(t){console.log("[Chart Expand] \u5C55\u958B\u5716\u8868");let a=this.getModalTarget(),e=a.ownerDocument||document;console.log("[Chart Expand] \u4F7F\u7528\u7684 document:",e===document?"\u7576\u524D iframe":"\u7236\u9801\u9762");let o=e.createElement("div");o.style.cssText=`
      position: fixed !important;
      top: 0 !important;
      left: 0 !important;
      right: 0 !important;
      bottom: 0 !important;
      background: rgba(0, 0, 0, 0.95) !important;
      z-index: 2147483647 !important;
      display: flex !important;
      align-items: center !important;
      justify-content: center !important;
      padding: 40px !important;
      margin: 0 !important;
    `;let i=this.getOverlayTheme(e),s=e.createElement("div");s.style.cssText=`
      width: 100%;
      max-width: 1400px;
      max-height: 90vh;
      background: ${i.surface};
      border: 1px solid ${i.border};
      border-radius: 16px;
      padding: 24px;
      position: relative;
      box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
    `;let n=e.createElement("button");n.innerHTML=`
      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" viewBox="0 0 16 16">
        <path d="M2.146 2.854a.5.5 0 1 1 .708-.708L8 7.293l5.146-5.147a.5.5 0 0 1 .708.708L8.707 8l5.147 5.146a.5.5 0 0 1-.708.708L8 8.707l-5.146 5.147a.5.5 0 0 1-.708-.708L7.293 8z"/>
      </svg>
    `,n.style.cssText=`
      position: absolute;
      top: 16px;
      right: 16px;
      background: transparent;
      border: none;
      color: ${i.textMuted};
      cursor: pointer;
      width: 36px;
      height: 36px;
      border-radius: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      transition: all 0.2s;
      z-index: 10;
    `;let l=()=>{console.log("[Chart Expand] \u95DC\u9589\u5716\u8868\u6A21\u614B\u8996\u7A97"),a.removeChild(o)};n.onmouseenter=()=>{n.style.background=i.hover,n.style.color=i.text},n.onmouseleave=()=>{n.style.background="transparent",n.style.color=i.textMuted},n.onclick=l;let r=e.createElement("div");r.className="chart-area",r.setAttribute("data-chart-xml",encodeURIComponent(t)),r.style.cssText="width: 100%; height: calc(90vh - 100px);";let p="expanded-chart-"+Date.now(),h=e.createElement("canvas");h.id=p,h.style.cssText="max-height: 100%; width: 100%;",r.appendChild(h),s.appendChild(n),s.appendChild(r),o.appendChild(s),a.appendChild(o),window.ChartRenderer&&setTimeout(()=>{window.ChartRenderer.renderInto(r,t)},100),o.onclick=m=>{m.target===o&&a.removeChild(o)}}};var H=class d{constructor(t){this.emptyState=null;this.messages=[];this.typingIndicator=null;this.config=t,this.container=c("div","aichathub-body"),this.showEmptyState()}static{this.OVERLAY_Z_INDEX=2147483646}static{this.TOAST_Z_INDEX=2147483647}isDarkTheme(){let t=String(this.config.chatBackgroundColor||"#f8fafc").replace("#",""),a=t.length===3?t.split("").map(n=>n+n).join(""):t.padEnd(6,"0").slice(0,6),e=parseInt(a.slice(0,2),16),o=parseInt(a.slice(2,4),16),i=parseInt(a.slice(4,6),16);return(.299*e+.587*o+.114*i)/255<.52}showEmptyState(){this.emptyState=c("div","aichathub-empty-state");let t=c("div","aichathub-empty-icon");t.innerHTML=`
      <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" fill="currentColor" viewBox="0 0 16 16">
        <path d="M5 8a1 1 0 1 1-2 0 1 1 0 0 1 2 0m4 0a1 1 0 1 1-2 0 1 1 0 0 1 2 0m3 1a1 1 0 1 0 0-2 1 1 0 0 0 0 2"/>
      </svg>
    `;let a=c("div","aichathub-empty-text",this.config.welcomeMessage);this.emptyState.appendChild(t),this.emptyState.appendChild(a),this.container.appendChild(this.emptyState)}removeEmptyState(){this.emptyState&&(this.emptyState.remove(),this.emptyState=null)}showTypingIndicator(){this.typingIndicator||(this.typingIndicator=c("div","aichathub-msg aichathub-msg-assistant aichathub-typing"),this.typingIndicator.innerHTML=`
      <div class="aichathub-typing-dots">
        <span class="aichathub-typing-dot"></span>
        <span class="aichathub-typing-dot"></span>
        <span class="aichathub-typing-dot"></span>
      </div>
    `,this.container.appendChild(this.typingIndicator),this.scrollToBottom())}hideTypingIndicator(){this.typingIndicator&&(this.typingIndicator.remove(),this.typingIndicator=null)}extractMapXml(t){if(!t)return null;let a=/<map(\s[^>]*)?>[\s\S]*?<\/map>/gi,e=t.match(a);if(!e||e.length===0)return null;let o=null,i=0;for(let s of e){let n=(s.match(/<location/gi)||[]).length;n>0&&n>i&&s.trim().startsWith("<map")&&(i=n,o=s)}if(o){let s=o.indexOf("<map");s>0&&(o=o.substring(s))}return o}extractChartXml(t){let a=t?.match(/<chart[\s\S]*?<\/chart>/i);return a?a[0]:null}stripMapXml(t){return t.replace(/<map[\s\S]*?<\/map>/gi,"").trim()}stripChartXml(t){return t.replace(/<chart[\s\S]*?<\/chart>/gi,"").trim()}parseMapXml(t){if(!t)return[];let a=[];return new DOMParser().parseFromString(t,"text/xml").querySelectorAll("location").forEach(s=>{let n=s.getAttribute("name"),l=s.getAttribute("englishName")||s.getAttribute("english")||"",r=parseFloat(s.getAttribute("lat")||"0"),p=parseFloat(s.getAttribute("lng")||"0"),h=s.getAttribute("description")||"";n&&!isNaN(r)&&!isNaN(p)&&r!==0&&p!==0&&a.push({name:n,englishName:l,lat:r,lng:p,description:h})}),a}parseMarkdown(t){if(!t)return"";let a=this.extractMapXml(t),e=this.extractChartXml(t),o=t;a&&(o=this.stripMapXml(o)),e&&(o=this.stripChartXml(o));let i="";if(typeof window.marked<"u")try{i=window.marked.parse(o)}catch(s){console.error("[MessageList] Markdown \u89E3\u6790\u932F\u8AA4:",s),i=x(o)}else i=x(o).replace(/\n/g,"<br>");if(i=G(i),a){let s=this.parseMapXml(a);s.length>0&&(i+=`<div class="map-area" data-locations="${encodeURIComponent(JSON.stringify(s))}" style="margin-top: 1em;"></div>`)}return e&&(i+=`<div class="chart-area" data-chart-xml="${encodeURIComponent(e)}" style="margin-top: 1em;"></div>`),i}addMessage(t,a,e){this.messages.length===0&&this.removeEmptyState(),this.messages.push(t);let o=c("div",`aichathub-msg aichathub-msg-${t.role}`);if(o.id=t.id,o.setAttribute("data-message-id",t.id),o.setAttribute("data-role",t.role),t.role==="user"){let i=c("div",""),s=c("div","");s.style.whiteSpace="pre-wrap",s.style.wordBreak="break-word",s.textContent=t.content,i.appendChild(s);let n=c("div","aichathub-msg-time");n.textContent=this.formatTimestamp(t.timestamp),i.appendChild(n),o.appendChild(i)}else if(t.role==="assistant"){let i=c("div","markdown-content");i.innerHTML=this.parseMarkdown(t.content),o.appendChild(i);let s=c("div","aichathub-msg-time");s.textContent=this.formatTimestamp(t.timestamp),o.appendChild(s),setTimeout(()=>{this.renderMapsIn(o),this.renderChartsIn(o)},100)}else{this.element.classList.remove("expanded");o.textContent=t.content;let i=c("div","aichathub-msg-time");i.textContent=this.formatTimestamp(t.timestamp),o.appendChild(i)}if(t.role==="assistant"&&a){let i=c("div","aichathub-msg-actions"),s=c("button","aichathub-action-btn");s.title="\u91CD\u65B0\u751F\u6210",s.innerHTML=`
        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" fill="currentColor" viewBox="0 0 16 16">
          <path fill-rule="evenodd" d="M8 3a5 5 0 1 0 4.546 2.914.5.5 0 0 1 .908-.417A6 6 0 1 1 8 2z"/>
          <path d="M8 4.466V.534a.25.25 0 0 1 .41-.192l2.36 1.966c.12.1.12.284 0 .384L8.41 4.658A.25.25 0 0 1 8 4.466"/>
        </svg>
      `;let n=this.findPreviousUserMessage(t.id);if(n&&(s.onclick=()=>a(t.id,n)),i.appendChild(s),e){let l=c("button","aichathub-action-btn aichathub-feedback-btn");l.title="\u6EFF\u610F",l.setAttribute("data-feedback-type","0"),l.innerHTML=`
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" fill="currentColor" viewBox="0 0 16 16">
            <path d="M8.864.046C7.908-.193 7.02.53 6.956 1.466c-.072 1.051-.23 2.016-.428 2.59-.125.36-.479 1.013-1.04 1.639-.557.623-1.282 1.178-2.131 1.41C2.685 7.288 2 7.87 2 8.72v4.001c0 .845.682 1.464 1.448 1.545 1.07.114 1.564.415 2.068.723l.048.03c.272.165.578.348.97.484.397.136.861.217 1.466.217h3.5c.937 0 1.599-.477 1.934-1.064a1.86 1.86 0 0 0 .254-.912c0-.152-.023-.312-.077-.464.201-.263.38-.578.488-.901.11-.33.172-.762.004-1.149.069-.13.12-.269.159-.403.077-.27.113-.568.113-.857 0-.288-.036-.585-.113-.856a2.144 2.144 0 0 0-.138-.362 1.9 1.9 0 0 0 .234-1.734c-.206-.592-.682-1.1-1.2-1.272-.847-.282-1.803-.276-2.516-.211a9.84 9.84 0 0 0-.443.05 9.365 9.365 0 0 0-.062-4.509A1.38 1.38 0 0 0 9.125.111L8.864.046zM11.5 14.721H8c-.51 0-.863-.069-1.14-.164-.281-.097-.506-.228-.776-.393l-.04-.024c-.555-.339-1.198-.731-2.49-.868-.333-.036-.554-.29-.554-.55V8.72c0-.254.226-.543.62-.65 1.095-.3 1.977-.996 2.614-1.708.635-.71 1.064-1.475 1.238-1.978.243-.7.407-1.768.482-2.85.025-.362.36-.594.667-.518l.262.066c.16.04.258.143.288.255a8.34 8.34 0 0 1-.145 4.725.5.5 0 0 0 .595.644l.003-.001.014-.003.058-.014a8.908 8.908 0 0 1 1.036-.157c.663-.06 1.457-.054 2.11.164.175.058.45.3.57.65.107.308.087.67-.266 1.022l-.353.353.353.354c.043.043.105.141.154.315.048.167.075.37.075.581 0 .212-.027.414-.075.582-.05.174-.111.272-.154.315l-.353.353.353.354c.047.047.109.177.005.488a2.224 2.224 0 0 1-.505.805l-.353.353.353.354c.006.005.041.05.041.17a.866.866 0 0 1-.121.416c-.165.288-.503.56-1.066.56z"/>
          </svg>
        `,l.onclick=()=>{e(t.id,0),this.updateFeedbackButtons(o,0)},i.appendChild(l);let r=c("button","aichathub-action-btn aichathub-feedback-btn");r.title="\u4E0D\u6EFF\u610F",r.setAttribute("data-feedback-type","1"),r.innerHTML=`
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" fill="currentColor" viewBox="0 0 16 16">
            <path d="M8.864 15.674c-.956.24-1.843-.484-1.908-1.42-.072-1.05-.23-2.015-.428-2.59-.125-.36-.479-1.012-1.04-1.638-.557-.624-1.282-1.179-2.131-1.41C2.685 8.432 2 7.85 2 7V3c0-.845.682-1.464 1.448-1.546 1.07-.113 1.564-.415 2.068-.723l.048-.029c.272-.166.578-.349.97-.484C6.931.08 7.395 0 8 0h3.5c.937 0 1.599.478 1.934 1.064.164.287.254.607.254.913 0 .152-.023.312-.077.464.201.262.38.577.488.9.11.33.172.762.004 1.15.069.13.12.268.159.403.077.27.113.567.113.856 0 .289-.036.586-.113.856-.035.12-.08.244-.138.363.394.571.418 1.2.234 1.733-.206.592-.682 1.1-1.2 1.272-.847.283-1.803.276-2.516.211a9.877 9.877 0 0 1-.443-.05 9.364 9.364 0 0 1-.062 4.51c-.138.508-.55.848-1.012.964l-.261.065zM11.5 1H8c-.51 0-.863.068-1.14.163-.281.097-.506.229-.776.393l-.04.025c-.555.338-1.198.73-2.49.868-.333.035-.554.29-.554.55V7c0 .255.226.543.62.65 1.095.3 1.977.997 2.614 1.709.635.71 1.064 1.475 1.238 1.977.243.7.407 1.768.482 2.85.025.362.36.595.667.518l.262-.065c.16-.04.258-.144.288-.255a8.34 8.34 0 0 0-.145-4.726.5.5 0 0 1 .595-.643h.003l.014.004.058.013a8.912 8.912 0 0 0 1.036.157c.663.06 1.457.054 2.11-.163.175-.059.45-.301.57-.651.107-.308.087-.67-.266-1.021L12.793 7l.353-.354c.043-.042.105-.14.154-.315.048-.167.075-.37.075-.581 0-.211-.027-.414-.075-.581-.05-.174-.111-.273-.154-.315l-.353-.354.353-.354c.047-.047.109-.176.005-.488a2.224 2.224 0 0 0-.505-.804l-.353-.354.353-.354c.006-.005.041-.05.041-.17a.866.866 0 0 0-.121-.415C12.4 1.272 12.063 1 11.5 1z"/>
          </svg>
        `,r.onclick=()=>{e(t.id,1),this.updateFeedbackButtons(o,1)},i.appendChild(r);let p=c("button","aichathub-action-btn aichathub-feedback-btn");p.title="\u56DE\u5831\u554F\u984C",p.setAttribute("data-feedback-type","2"),p.innerHTML=`
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" fill="currentColor" viewBox="0 0 16 16">
            <path d="M14.778.085A.5.5 0 0 1 15 .5V8a.5.5 0 0 1-.314.464L14.5 8l.186.464-.003.001-.006.003-.023.009a12.435 12.435 0 0 1-.397.15c-.264.095-.631.223-1.047.35-.816.252-1.879.523-2.71.523-.847 0-1.548-.28-2.158-.525l-.028-.01C7.68 8.71 7.14 8.5 6.5 8.5c-.7 0-1.638.23-2.437.477A19.626 19.626 0 0 0 3 9.342V15.5a.5.5 0 0 1-1 0V.5a.5.5 0 0 1 1 0v.282c.226-.079.496-.17.79-.26C4.606.272 5.67 0 6.5 0c.84 0 1.524.277 2.121.519l.043.018C9.286.788 9.828 1 10.5 1c.7 0 1.638-.23 2.437-.477a19.587 19.587 0 0 0 1.349-.476l.019-.007.004-.002h.001"/>
          </svg>
        `,p.onclick=()=>{this.showReportModal(t.id,h=>{e(t.id,2,h),this.updateFeedbackButtons(o,2)})},i.appendChild(p)}o.appendChild(i)}this.container.appendChild(o),this.scrollToBottom()}findPreviousUserMessage(t){let a=this.messages.findIndex(e=>e.id===t);for(let e=a-1;e>=0;e--)if(this.messages[e].role==="user")return this.messages[e].content;return null}updateFeedbackButtons(t,a){t.querySelectorAll(".aichathub-feedback-btn").forEach(o=>{let i=o,s=parseInt(i.getAttribute("data-feedback-type")||"-1");s===a?(i.style.color=s===0?"#16a34a":s===1?"#dc2626":"#ea580c",i.style.opacity="1"):(i.style.color="",i.style.opacity="0.5")})}formatTimestamp(t){let a=new Date(t),o=new Date().getTime()-a.getTime(),i=Math.floor(o/6e4);if(i<1)return"\u525B\u525B";if(i<60)return`${i} \u5206\u9418\u524D`;let s=Math.floor(i/60);if(s<24)return`${s} \u5C0F\u6642\u524D`;let n=a.getHours().toString().padStart(2,"0"),l=a.getMinutes().toString().padStart(2,"0");return`${a.getMonth()+1}/${a.getDate()} ${n}:${l}`}renderMapsIn(t){t.querySelectorAll('.map-area:not([data-rendered="1"])').forEach(e=>{try{let o=decodeURIComponent(e.getAttribute("data-locations")||"[]"),i=JSON.parse(o);if(i.length===0||typeof window.L>"u"){e.innerHTML='<div style="padding: 12px; background: #e0f2fe; border-left: 3px solid #0284c7; font-size: 0.9em;">\u{1F4CD} \u5730\u5716\u8CC7\u6599\u5DF2\u751F\u6210\uFF08\u9700\u8981 Leaflet.js \u652F\u63F4\uFF09</div>';return}let s=document.createElement("div");s.style.cssText="position: relative;";let n="map-"+Date.now()+"-"+Math.random().toString(36).substr(2,9),l=document.createElement("div");l.id=n,l.style.cssText="height: 400px; border-radius: 8px; overflow: hidden; border: 1px solid #e5e7eb;";let r=document.createElement("button");r.className="map-expand-btn",r.type="button",r.title="\u5168\u5C4F\u6AA2\u8996\u5730\u5716",r.innerHTML=`
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
            <path d="M1.5 1a.5.5 0 0 0-.5.5v4a.5.5 0 0 1-1 0v-4A1.5 1.5 0 0 1 1.5 0h4a.5.5 0 0 1 0 1h-4zM10 .5a.5.5 0 0 1 .5-.5h4A1.5 1.5 0 0 1 16 1.5v4a.5.5 0 0 1-1 0v-4a.5.5 0 0 0-.5-.5h-4a.5.5 0 0 1-.5-.5zM.5 10a.5.5 0 0 1 .5.5v4a.5.5 0 0 0 .5.5h4a.5.5 0 0 1 0 1h-4A1.5 1.5 0 0 1 0 14.5v-4a.5.5 0 0 1 .5-.5zm15 0a.5.5 0 0 1 .5.5v4a1.5 1.5 0 0 1-1.5 1.5h-4a.5.5 0 0 1 0-1h4a.5.5 0 0 0 .5-.5v-4a.5.5 0 0 1 .5-.5z"/>
          </svg>
        `,r.style.cssText=`
          position: absolute !important;
          top: 12px !important;
          right: 12px !important;
          background: rgba(255, 255, 255, 0.95) !important;
          border: 1px solid #e4e4e7 !important;
          border-radius: 6px !important;
          width: 32px !important;
          height: 32px !important;
          cursor: pointer !important;
          display: flex !important;
          align-items: center !important;
          justify-content: center !important;
          color: #52525b !important;
          transition: all 0.2s !important;
          box-shadow: 0 2px 8px rgba(0,0,0,0.15) !important;
          z-index: 1000 !important;
          pointer-events: auto !important;
          padding: 0 !important;
          margin: 0 !important;
        `,r.addEventListener("mouseenter",()=>{r.style.background="white",r.style.color="#18181b",r.style.transform="scale(1.05)"}),r.addEventListener("mouseleave",()=>{r.style.background="rgba(255, 255, 255, 0.95)",r.style.color="#52525b",r.style.transform="scale(1)"}),r.addEventListener("click",p=>{p.preventDefault(),p.stopPropagation(),console.log("[Map Expand] \u5C55\u958B\u6309\u9215\u88AB\u9EDE\u64CA\uFF0C\u5730\u9EDE\u6578\u91CF:",i.length),L.expandMap(i)}),s.appendChild(l),s.appendChild(r),e.innerHTML="",e.appendChild(s),e.setAttribute("data-rendered","1"),setTimeout(()=>{L.initializeMap(n,i)},100)}catch(o){console.error("\u5730\u5716\u6E32\u67D3\u5931\u6557",o),e.innerHTML='<div style="padding: 12px; background: #fee2e2; border-left: 3px solid #ef4444; font-size: 0.9em;">\u274C \u5730\u5716\u8F09\u5165\u5931\u6557</div>'}})}renderChartsIn(t){t.querySelectorAll('.chart-area:not([data-rendered="1"])').forEach(e=>{try{let o=decodeURIComponent(e.getAttribute("data-chart-xml")||"");if(!o||typeof window.Chart>"u"){e.innerHTML='<div style="padding: 12px; background: #fef3c7; border-left: 3px solid #f59e0b; font-size: 0.9em;">\u{1F4CA} \u5716\u8868\u8CC7\u6599\u5DF2\u751F\u6210\uFF08\u9700\u8981 Chart.js \u652F\u63F4\uFF09</div>';return}let i=document.createElement("div");i.style.cssText="position: relative;";let s="chart-"+Date.now()+"-"+Math.random().toString(36).substr(2,9),n=document.createElement("canvas");n.id=s,n.style.cssText="width: 100%; height: 320px; max-height: 400px; display: block;";let l=document.createElement("button");l.className="chart-expand-btn",l.type="button",l.title="\u5168\u5C4F\u6AA2\u8996\u5716\u8868",l.innerHTML=`
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
            <path d="M1.5 1a.5.5 0 0 0-.5.5v4a.5.5 0 0 1-1 0v-4A1.5 1.5 0 0 1 1.5 0h4a.5.5 0 0 1 0 1h-4zM10 .5a.5.5 0 0 1 .5-.5h4A1.5 1.5 0 0 1 16 1.5v4a.5.5 0 0 1-1 0v-4a.5.5 0 0 0-.5-.5h-4a.5.5 0 0 1-.5-.5zM.5 10a.5.5 0 0 1 .5.5v4a.5.5 0 0 0 .5.5h4a.5.5 0 0 1 0 1h-4A1.5 1.5 0 0 1 0 14.5v-4a.5.5 0 0 1 .5-.5zm15 0a.5.5 0 0 1 .5.5v4a1.5 1.5 0 0 1-1.5 1.5h-4a.5.5 0 0 1 0-1h4a.5.5 0 0 0 .5-.5v-4a.5.5 0 0 1 .5-.5z"/>
          </svg>
        `,l.style.cssText=`
          position: absolute !important;
          top: 8px !important;
          right: 8px !important;
          background: rgba(255, 255, 255, 0.9) !important;
          border: 1px solid #e4e4e7 !important;
          border-radius: 6px !important;
          width: 28px !important;
          height: 28px !important;
          cursor: pointer !important;
          display: flex !important;
          align-items: center !important;
          justify-content: center !important;
          color: #52525b !important;
          transition: all 0.2s !important;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1) !important;
          z-index: 10 !important;
          pointer-events: auto !important;
          padding: 0 !important;
          margin: 0 !important;
        `,l.addEventListener("mouseenter",()=>{l.style.background="white",l.style.color="#18181b",l.style.transform="scale(1.05)"}),l.addEventListener("mouseleave",()=>{l.style.background="rgba(255, 255, 255, 0.9)",l.style.color="#52525b",l.style.transform="scale(1)"}),l.addEventListener("click",r=>{r.preventDefault(),r.stopPropagation(),console.log("[Chart Expand] \u5C55\u958B\u6309\u9215\u88AB\u9EDE\u64CA"),S.expandChart(o)}),e.innerHTML="",e.appendChild(i),e.setAttribute("data-rendered","1"),i.appendChild(n),i.appendChild(l),this.renderChartCanvas(n,o)}catch(o){console.error("[Chart] \u8655\u7406\u5716\u8868\u6642\u51FA\u932F:",o),e.innerHTML='<div style="padding: 12px; background: #fee2e2; border-left: 3px solid #dc2626; font-size: 0.9em;">\u274C \u5716\u8868\u6E32\u67D3\u5931\u6557</div>'}})}renderChartCanvas(t,a){typeof window.Chart>"u"||setTimeout(()=>{try{let o=new DOMParser().parseFromString(a,"text/xml"),i=o.documentElement.getAttribute("type")||"bar",s=o.documentElement.getAttribute("title")||"",n=[],l=[],r=Array.from(o.querySelectorAll("series"));if(r.length>0){Array.from(o.querySelectorAll("labels > label")).forEach(m=>n.push((m.textContent||"").trim()));let h=["#3b82f6","#10b981","#f59e0b","#ef4444","#8b5cf6","#06b6d4","#f97316"];r.forEach((m,g)=>{let b=Array.from(m.querySelectorAll("value")).map(u=>parseFloat(u.textContent||"0"));if(n.length===0)for(let u=0;u<b.length;u++)n.push(`Item ${u+1}`);l.push({label:m.getAttribute("name")||`Series ${g+1}`,data:b,backgroundColor:i==="line"?"rgba(59, 130, 246, 0.12)":h[g%h.length],borderColor:m.getAttribute("color")||h[g%h.length],borderWidth:2,tension:i==="line"?.35:0,fill:i==="line"})})}else{let p=o.querySelectorAll("data"),h=[];p.forEach((m,g)=>{n.push(m.getAttribute("label")||`Item ${g+1}`),h.push(parseFloat(m.getAttribute("value")||"0"))}),l.push({label:s||"Data",data:h,backgroundColor:i==="line"?"rgba(59, 130, 246, 0.12)":"rgba(59, 130, 246, 0.8)",borderColor:"rgb(59, 130, 246)",borderWidth:2,tension:i==="line"?.35:0,fill:i==="line"})}new window.Chart(t,{type:i,data:{labels:n,datasets:l},options:{responsive:!0,maintainAspectRatio:!1,plugins:{legend:{display:!!s},title:{display:!!s,text:s}}}})}catch(e){console.error("[Chart] \u6E32\u67D3\u932F\u8AA4:",e)}},100)}removeMessage(t){let a=document.getElementById(t);a&&a.remove(),this.messages=this.messages.filter(e=>e.id!==t),this.messages.length===0&&this.showEmptyState()}clear(){this.container.innerHTML="",this.messages=[],this.showEmptyState()}updateWelcomeMessage(t){if(this.config.welcomeMessage=t,this.emptyState){let a=this.emptyState.querySelector(".aichathub-empty-text");a&&(a.textContent=t)}}loadMessages(t,a,e){this.clear(),t.forEach(o=>this.addMessage(o,a,e))}scrollToBottom(){requestAnimationFrame(()=>{this.container.scrollTop=this.container.scrollHeight})}refreshAllMaps(){console.log("[MessageList] \u5237\u65B0\u6240\u6709\u5730\u5716\u5927\u5C0F");let t=this.container.querySelectorAll('.map-area[data-rendered="1"]');console.log("[MessageList] \u627E\u5230",t.length,"\u500B\u5730\u5716"),t.forEach((a,e)=>{let o=a.querySelector('[id^="map-"]');if(!o){console.log("[MessageList] \u5730\u5716",e,"- \u627E\u4E0D\u5230\u5730\u5716\u5BB9\u5668");return}let i=o._leaflet_map;if(!i){console.log("[MessageList] \u5730\u5716",e,"- \u627E\u4E0D\u5230 Leaflet \u5BE6\u4F8B");return}console.log("[MessageList] \u5730\u5716",e,"- \u8ABF\u7528 invalidateSize()");try{i.invalidateSize(),console.log("[MessageList] \u5730\u5716",e,"- \u5237\u65B0\u5B8C\u6210")}catch(s){console.error("[MessageList] \u5730\u5716",e,"- \u5237\u65B0\u5931\u6557:",s)}})}showReportModal(t,a){let e=this.isDarkTheme(),o=e?"#18181b":"white",i=e?"1px solid rgba(255,255,255,0.14)":"none",s=e?"#f4f4f5":"#18181b",n=e?"#d4d4d8":"#3f3f46",l=e?"#a1a1aa":"#71717a",r=e?"rgba(255,255,255,0.06)":"white",p=e?"rgba(255,255,255,0.2)":"#d4d4d8",h=e?"rgba(255,255,255,0.06)":"white",m=e?"rgba(255,255,255,0.12)":"#f4f4f5",g=c("div","aichathub-report-modal");g.setAttribute("role","dialog"),g.setAttribute("aria-modal","true"),g.style.cssText=`
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(0, 0, 0, 0.5);
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: ${d.OVERLAY_Z_INDEX};
      padding: 20px;
    `;let b=c("div","aichathub-report-modal-content");b.setAttribute("role","document");b.style.cssText=`
      background: ${o};
      border: ${i};
      border-radius: 8px;
      width: 100%;
      max-width: 480px;
      box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
      display: flex;
      flex-direction: column;
      max-height: 90vh;
    `;let u=this.createReportModalHeader(g),v=c("div","aichathub-report-modal-body");v.style.cssText="padding: 20px; flex: 1; overflow-y: auto;";let y=c("label","","\u8ACB\u63CF\u8FF0\u60A8\u9047\u5230\u7684\u554F\u984C\uFF1A");y.style.cssText=`display: block; font-size: 13px; font-weight: 600; color: ${n}; margin-bottom: 8px;`;let f=document.createElement("textarea");f.rows=6,f.placeholder="\u8ACB\u8A73\u7D30\u8AAA\u660E\u60A8\u9047\u5230\u7684\u554F\u984C...",f.style.cssText=`
      width: 100%;
      padding: 10px 12px;
      border: 1px solid ${p};
      border-radius: 6px;
      font-size: 14px;
      color: ${s};
      background: ${r};
      resize: vertical;
      font-family: inherit;
      transition: border-color 0.2s;
      box-sizing: border-box;
    `,f.style.setProperty("caret-color",s),f.onfocus=()=>f.style.borderColor="#3b82f6",f.onblur=()=>f.style.borderColor=p,v.appendChild(y),v.appendChild(f);let z=this.createReportModalFooter(g,f,a,{headingText:s,mutedText:l,inputBorder:p,cancelBg:h,cancelBgHover:m});b.appendChild(u),b.appendChild(v),b.appendChild(z),g.appendChild(b);let W=()=>{g.remove()};g.onclick=U=>{U.target===g&&W()};let J=U=>{if(U.key==="Escape"){U.preventDefault(),W();return}if(U.key!=="Tab")return;let _=Array.from(g.querySelectorAll("button, textarea, [href], input, select, [tabindex]:not([tabindex='-1'])")).filter(X=>!X.disabled&&X.offsetParent!==null),F=_[0],q=_[_.length-1];if(!F||!q)return;U.shiftKey&&document.activeElement===F?(U.preventDefault(),q.focus()):!U.shiftKey&&document.activeElement===q&&(U.preventDefault(),F.focus())};g.addEventListener("keydown",J),document.body.appendChild(g),setTimeout(()=>f.focus(),100)}createReportModalHeader(t){let a=this.isDarkTheme(),e=a?"#f4f4f5":"#18181b",o=a?"#a1a1aa":"#71717a",i=a?"rgba(255,255,255,0.14)":"#e5e7eb",s=a?"rgba(255,255,255,0.12)":"#f4f4f5",n=c("div","aichathub-report-modal-header");n.style.cssText=`padding: 16px 20px; border-bottom: 1px solid ${i}; display: flex; justify-content: space-between; align-items: center;`;let l=c("h3","","\u56DE\u5831\u554F\u984C");l.style.cssText=`margin: 0; font-size: 16px; font-weight: 600; color: ${e};`;let r=c("button","aichathub-report-modal-close");return r.innerHTML="&times;",r.style.cssText=`background: none; border: none; font-size: 24px; color: ${o}; cursor: pointer; padding: 0; width: 24px; height: 24px; display: flex; align-items: center; justify-content: center; border-radius: 4px; transition: background-color 0.2s;`,r.onmouseover=()=>r.style.backgroundColor=s,r.onmouseout=()=>r.style.backgroundColor="transparent",r.onclick=()=>t.remove(),n.appendChild(l),n.appendChild(r),n}createReportModalFooter(t,a,e,o){let s=this.isDarkTheme()?"rgba(255,255,255,0.14)":"#e5e7eb",n=c("div","aichathub-report-modal-footer");n.style.cssText=`padding: 16px 20px; border-top: 1px solid ${s}; display: flex; justify-content: flex-end; gap: 12px;`;let l=c("button","","\u53D6\u6D88");l.style.cssText=`padding: 8px 16px; border: 1px solid ${o.inputBorder}; background: ${o.cancelBg}; color: ${o.mutedText}; border-radius: 6px; font-size: 14px; font-weight: 500; cursor: pointer; transition: all 0.2s;`,l.onmouseover=()=>{l.style.backgroundColor=o.cancelBgHover,l.style.borderColor=o.headingText},l.onmouseout=()=>{l.style.backgroundColor=o.cancelBg,l.style.borderColor=o.inputBorder},l.onclick=()=>t.remove();let r=c("button","","\u63D0\u4EA4");return r.style.cssText="padding: 8px 16px; border: none; background: #18181b; color: white; border-radius: 6px; font-size: 14px; font-weight: 500; cursor: pointer; transition: background-color 0.2s;",r.onmouseover=()=>r.style.backgroundColor="#27272a",r.onmouseout=()=>r.style.backgroundColor="#18181b",r.onclick=()=>{let p=a.value.trim();p?(e(p),t.remove(),this.showToast("\u611F\u8B1D\u60A8\u7684\u56DE\u5831\uFF01\u6211\u5011\u6703\u76E1\u5FEB\u8655\u7406\u3002")):(a.focus(),a.style.borderColor="#ef4444")},n.appendChild(l),n.appendChild(r),n}showToast(t){let a=c("div","aichathub-toast",t);if(a.style.cssText=`
      position: fixed;
      top: 20px;
      left: 50%;
      transform: translateX(-50%);
      background: #18181b;
      color: white;
      padding: 12px 20px;
      border-radius: 8px;
      font-size: 14px;
      box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
      z-index: ${d.TOAST_Z_INDEX};
      animation: aichathub-toast-in 0.3s ease-out;
    `,!document.getElementById("aichathub-toast-styles")){let e=document.createElement("style");e.id="aichathub-toast-styles",e.textContent=`
        @keyframes aichathub-toast-in {
          from {
            opacity: 0;
            transform: translateX(-50%) translateY(-10px);
          }
          to {
            opacity: 1;
            transform: translateX(-50%) translateY(0);
          }
        }
      `,document.head.appendChild(e)}document.body.appendChild(a),setTimeout(()=>{a.style.opacity="0",a.style.transition="opacity 0.3s ease-out",setTimeout(()=>a.remove(),300)},2e3)}getElement(){return this.container}getMessages(){return[...this.messages]}};var A=class{constructor(){this.container=c("div","aichathub-input-container"),this.tagsContainer=c("div","aichathub-tags-container"),this.tagsContainer.style.display="none",this.tagScrollLeft=c("button","aichathub-tag-scroll-btn aichathub-tag-scroll-left"),this.tagScrollLeft.innerHTML='<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16"><path fill-rule="evenodd" d="M11.354 1.646a.5.5 0 0 1 0 .708L5.707 8l5.647 5.646a.5.5 0 0 1-.708.708l-6-6a.5.5 0 0 1 0-.708l6-6a.5.5 0 0 1 .708 0z"/></svg>',this.tagScrollLeft.onclick=()=>this.scrollLeft(),this.tagScrollLeft.style.opacity="0",this.tagScrollLeft.style.pointerEvents="none",this.tagsScroll=c("div","aichathub-tags-scroll"),this.tagsScroll.addEventListener("scroll",()=>this.updateScrollButtons()),this.tagScrollRight=c("button","aichathub-tag-scroll-btn aichathub-tag-scroll-right"),this.tagScrollRight.innerHTML='<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16"><path fill-rule="evenodd" d="M4.646 1.646a.5.5 0 0 1 .708 0l6 6a.5.5 0 0 1 0 .708l-6 6a.5.5 0 0 1-.708-.708L10.293 8 4.646 2.354a.5.5 0 0 1 0-.708z"/></svg>',this.tagScrollRight.onclick=()=>this.scrollRight(),this.tagScrollRight.style.opacity="0",this.tagScrollRight.style.pointerEvents="none",this.tagsContainer.appendChild(this.tagScrollLeft),this.tagsContainer.appendChild(this.tagsScroll),this.tagsContainer.appendChild(this.tagScrollRight),this.inputWrapper=c("div","aichathub-input-wrapper"),this.textarea=c("textarea","aichathub-input"),this.textarea.rows=1,this.textarea.placeholder="\u8F38\u5165\u8A0A\u606F...",this.textarea.setAttribute("aria-label","聊天輸入框"),this.sendButton=c("button","aichathub-send-btn"),this.sendButton.setAttribute("aria-label","送出訊息"),this.sendButton.innerHTML=`
      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
        <path d="M15.854.146a.5.5 0 0 1 .11.54l-5.819 14.547a.75.75 0 0 1-1.329.124l-3.178-4.995L.643 7.184a.75.75 0 0 1 .124-1.33L15.314.037a.5.5 0 0 1 .54.11ZM6.636 10.07l2.761 4.338L14.13 2.576zm6.787-8.201L1.591 6.602l4.339 2.76z"/>
      </svg>
    `,this.inputWrapper.appendChild(this.textarea),this.inputWrapper.appendChild(this.sendButton),this.container.appendChild(this.tagsContainer),this.container.appendChild(this.inputWrapper),this.textarea.style.height="52px",this.setupAutoResize()}setupAutoResize(){this.textarea.addEventListener("input",()=>{this.textarea.style.height="auto";let t=Math.max(52,Math.min(this.textarea.scrollHeight,200));this.textarea.style.height=t+"px"})}getValue(){return this.textarea.value.trim()}setValue(t){this.textarea.value=t,this.textarea.style.height="52px"}clear(){this.setValue("")}focus(){this.textarea.focus()}setDisabled(t){this.textarea.disabled=t,this.sendButton.disabled=t}onSend(t){this.sendButton.addEventListener("click",()=>{let a=this.getValue();a&&t(a)}),this.textarea.addEventListener("keydown",a=>{if(a.key==="Enter"&&!a.shiftKey){a.preventDefault();let e=this.getValue();e&&t(e)}})}setTags(t){if(this.tagsScroll.innerHTML="",t.length===0){this.tagsContainer.style.display="none";return}this.tagsContainer.style.display="block",t.forEach(a=>{let e=c("button","aichathub-tag-btn");e.textContent=a,e.addEventListener("click",()=>{this.onTagClickCallback?.(a)}),this.tagsScroll.appendChild(e)}),setTimeout(()=>this.updateScrollButtons(),100)}setTagsLoading(){this.tagsScroll.innerHTML="",this.tagsContainer.style.display="block";let t=c("div","aichathub-tag-loading");t.innerHTML='<div class="aichathub-tag-loading-spinner"></div><span>\u6B63\u5728\u7522\u751F\u5EFA\u8B70...</span>',this.tagsScroll.appendChild(t),this.tagScrollLeft.style.opacity="0",this.tagScrollLeft.style.pointerEvents="none",this.tagScrollRight.style.opacity="0",this.tagScrollRight.style.pointerEvents="none"}scrollLeft(){this.tagsScroll.scrollBy({left:-200,behavior:"smooth"})}scrollRight(){this.tagsScroll.scrollBy({left:200,behavior:"smooth"})}updateScrollButtons(){let{scrollLeft:t,scrollWidth:a,clientWidth:e}=this.tagsScroll;t>10?(this.tagScrollLeft.style.opacity="1",this.tagScrollLeft.style.pointerEvents="auto"):(this.tagScrollLeft.style.opacity="0",this.tagScrollLeft.style.pointerEvents="none"),t<a-e-10?(this.tagScrollRight.style.opacity="1",this.tagScrollRight.style.pointerEvents="auto"):(this.tagScrollRight.style.opacity="0",this.tagScrollRight.style.pointerEvents="none")}onTagClick(t){this.onTagClickCallback=t}clearTags(){this.setTags([])}getElement(){return this.container}};var $=class{constructor(t,a=!1){this.visible=!1;this.isExpanded=!1;this.originalWidth=0;this.originalHeight=0;this.clearCallback=null;this.closeCallback=null;console.log("[Panel] \u958B\u59CB\u521D\u59CB\u5316\uFF0CisEmbedded:",a),this.config=t,this.isEmbedded=a,console.log("[Panel] \u5275\u5EFA\u9762\u677F\u5143\u7D20"),this.element=this.createPanel(),console.log("[Panel] \u5275\u5EFA\u6A19\u982D\u5143\u7D20"),this.header=this.createHeader(),console.log("[Panel] \u5275\u5EFA MessageList \u5143\u4EF6"),this.messageList=new H(t),console.log("[Panel] \u5275\u5EFA Input \u5143\u4EF6"),this.input=new A;let e=c("div","aichathub-content-wrapper");e.appendChild(this.messageList.getElement()),e.appendChild(this.input.getElement()),this.element.appendChild(this.header),this.element.appendChild(e),this.titleElement=this.header.querySelector(".aichathub-title"),console.log("[Panel] \u521D\u59CB\u5316\u5B8C\u6210\uFF0Celement classList:",this.element.classList.toString())}createPanel(){let t=c("div","aichathub-panel");if(t.setAttribute("data-position",this.config.position||"bottom-right"),t.setAttribute("role","dialog"),t.setAttribute("aria-label","聊天面板"),t.setAttribute("aria-hidden","true"),this.isEmbedded&&t.classList.add("embedded"),!this.isEmbedded){t.style.width=`${this.config.width}px`,t.style.height=`${this.config.height}px`;let a=this.config.position||"bottom-right";a.includes("bottom")&&(t.style.bottom=`${this.config.bottomOffset}px`),a.includes("right")&&(t.style.right=`${this.config.rightOffset}px`)}return t}createHeader(){let t=c("div","aichathub-header"),a=c("div","aichathub-title-wrap");this.titleElement=c("span","aichathub-title",this.config.assistantName),a.appendChild(this.titleElement);let e=c("div","aichathub-header-actions"),o=c("button","aichathub-header-btn");if(o.setAttribute("title","\u6E05\u9664\u5C0D\u8A71"),o.setAttribute("aria-label","清除對話"),o.innerHTML=`
      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
        <path d="M2.5 1a1 1 0 0 0-1 1v1a1 1 0 0 0 1 1H3v9a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2V4h.5a1 1 0 0 0 1-1V2a1 1 0 0 0-1-1H10a1 1 0 0 0-1-1H7a1 1 0 0 0-1 1zm3 4a.5.5 0 0 1 .5.5v7a.5.5 0 0 1-1 0v-7a.5.5 0 0 1 .5-.5M8 5a.5.5 0 0 1 .5.5v7a.5.5 0 0 1-1 0v-7A.5.5 0 0 1 8 5m3 .5v7a.5.5 0 0 1-1 0v-7a.5.5 0 0 1 1 0"/>
      </svg>
    `,o.addEventListener("click",()=>{confirm("\u78BA\u5B9A\u8981\u6E05\u9664\u6240\u6709\u5C0D\u8A71\u55CE\uFF1F")&&this.clearCallback?.()}),e.appendChild(o),!this.isEmbedded){let i=c("button","aichathub-header-btn aichathub-expand");i.setAttribute("title","\u653E\u5927"),i.setAttribute("aria-label","放大聊天面板"),i.innerHTML=`
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
          <path d="M1.5 1a.5.5 0 0 0-.5.5v4a.5.5 0 0 1-1 0v-4A1.5 1.5 0 0 1 1.5 0h4a.5.5 0 0 1 0 1h-4zM10 .5a.5.5 0 0 1 .5-.5h4A1.5 1.5 0 0 1 16 1.5v4a.5.5 0 0 1-1 0v-4a.5.5 0 0 0-.5-.5h-4a.5.5 0 0 1-.5-.5zM.5 10a.5.5 0 0 1 .5.5v4a.5.5 0 0 0 .5.5h4a.5.5 0 0 1 0 1h-4A1.5 1.5 0 0 1 0 14.5v-4a.5.5 0 0 1 .5-.5zm15 0a.5.5 0 0 1 .5.5v4a1.5 1.5 0 0 1-1.5 1.5h-4a.5.5 0 0 1 0-1h4a.5.5 0 0 0 .5-.5v-4a.5.5 0 0 1 .5-.5z"/>
        </svg>
      `,i.addEventListener("click",()=>{this.toggleExpand()}),e.appendChild(i)}if(!this.isEmbedded){let i=c("button","aichathub-header-btn aichathub-close");i.setAttribute("title","\u95DC\u9589"),i.setAttribute("aria-label","關閉聊天面板"),i.innerHTML=`
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
          <path d="M2.146 2.854a.5.5 0 1 1 .708-.708L8 7.293l5.146-5.147a.5.5 0 0 1 .708.708L8.707 8l5.147 5.146a.5.5 0 0 1-.708.708L8 8.707l-5.146 5.147a.5.5 0 0 1-.708-.708L7.293 8z"/>
        </svg>
      `,i.addEventListener("click",()=>{this.close(),this.closeCallback?.()}),e.appendChild(i)}return t.appendChild(a),t.appendChild(e),t}getElement(){return this.element}getMessageList(){return this.messageList}getInput(){return this.input}open(){console.log("[Panel] open - \u88AB\u8ABF\u7528"),console.log("[Panel] open - \u5728 open \u4E4B\u524D\uFF0Cvisible =",this.visible),console.log("[Panel] open - \u5728 open \u4E4B\u524D\uFF0Celement.classList =",this.element.classList.toString()),this.visible=!0,this.element.classList.add("open"),this.element.setAttribute("aria-hidden","false"),console.log("[Panel] open - \u5728 open \u4E4B\u5F8C\uFF0Cvisible =",this.visible),console.log("[Panel] open - \u5728 open \u4E4B\u5F8C\uFF0Celement.classList =",this.element.classList.toString()),console.log("[Panel] open - element.style.display =",window.getComputedStyle(this.element).display),console.log("[Panel] open - element.style.opacity =",window.getComputedStyle(this.element).opacity),console.log("[Panel] open - element.style.visibility =",window.getComputedStyle(this.element).visibility),this.input.focus(),setTimeout(()=>{console.log("[Panel] open - \u5237\u65B0\u6240\u6709\u5730\u5716"),this.messageList.refreshAllMaps()},300),console.log("[Panel] open - \u5B8C\u6210")}close(){console.log("[Panel] close - \u88AB\u8ABF\u7528"),this.visible=!1,this.element.classList.remove("open"),this.element.setAttribute("aria-hidden","true"),console.log("[Panel] close - \u5B8C\u6210\uFF0Celement.classList:",this.element.classList.toString())}isOpen(){return this.visible}updateTitle(t){this.titleElement&&(this.titleElement.textContent=t)}onClear(t){this.clearCallback=t}onClose(t){this.closeCallback=t}toggleExpand(){if(!this.isEmbedded){if(this.isExpanded=!this.isExpanded,this.isExpanded){this.element.classList.add("expanded");this.originalWidth=this.config.width,this.originalHeight=this.config.height,this.element.style.width="calc(100vw - 40px)",this.element.style.height="calc(100vh - 40px)",this.element.style.top="20px",this.element.style.right="20px",this.element.style.bottom="auto",this.element.style.left="auto";let t=this.element.querySelector(".aichathub-expand");t&&(t.setAttribute("title","\u9084\u539F"),t.innerHTML=`
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
            <path d="M5.5 0a.5.5 0 0 1 .5.5v4A1.5 1.5 0 0 1 4.5 6h-4a.5.5 0 0 1 0-1h4a.5.5 0 0 0 .5-.5v-4a.5.5 0 0 1 .5-.5zm5 0a.5.5 0 0 1 .5.5v4a.5.5 0 0 0 .5.5h4a.5.5 0 0 1 0 1h-4A1.5 1.5 0 0 1 10 4.5v-4a.5.5 0 0 1 .5-.5zM0 10.5a.5.5 0 0 1 .5-.5h4A1.5 1.5 0 0 1 6 11.5v4a.5.5 0 0 1-1 0v-4a.5.5 0 0 0-.5-.5h-4a.5.5 0 0 1-.5-.5zm10 1a1.5 1.5 0 0 1 1.5-1.5h4a.5.5 0 0 1 0 1h-4a.5.5 0 0 0-.5.5v4a.5.5 0 0 1-1 0v-4z"/>
          </svg>
        `)}else{this.element.style.width=`${this.originalWidth}px`,this.element.style.height=`${this.originalHeight}px`;let t=this.config.position||"bottom-right";this.element.style.top="",this.element.style.right="",this.element.style.bottom="",this.element.style.left="",t.includes("bottom")?this.element.style.bottom=`${this.config.bottomOffset}px`:this.element.style.top=`${this.config.bottomOffset}px`,t.includes("right")?this.element.style.right=`${this.config.rightOffset}px`:this.element.style.left=`${this.config.rightOffset}px`;let a=this.element.querySelector(".aichathub-expand");a&&(a.setAttribute("title","\u653E\u5927"),a.innerHTML=`
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
            <path d="M1.5 1a.5.5 0 0 0-.5.5v4a.5.5 0 0 1-1 0v-4A1.5 1.5 0 0 1 1.5 0h4a.5.5 0 0 1 0 1h-4zM10 .5a.5.5 0 0 1 .5-.5h4A1.5 1.5 0 0 1 16 1.5v4a.5.5 0 0 1-1 0v-4a.5.5 0 0 0-.5-.5h-4a.5.5 0 0 1-.5-.5zM.5 10a.5.5 0 0 1 .5.5v4a.5.5 0 0 0 .5.5h4a.5.5 0 0 1 0 1h-4A1.5 1.5 0 0 1 0 14.5v-4a.5.5 0 0 1 .5-.5zm15 0a.5.5 0 0 1 .5.5v4a1.5 1.5 0 0 1-1.5 1.5h-4a.5.5 0 0 1 0-1h4a.5.5 0 0 0 .5-.5v-4a.5.5 0 0 1 .5-.5z"/>
          </svg>
        `)}setTimeout(()=>{console.log("[Panel] toggleExpand - \u5237\u65B0\u6240\u6709\u5730\u5716"),this.messageList.refreshAllMaps()},300)}}};function V(d,t){let a=d.chatBackgroundColor||"#f8fafc",e=d.themeColor||"#18181b",o=d.headerTextColor||"#ffffff",i=d.textColor||"#18181b",s=d.launcherIconColor||"#ffffff",n=D=>{let C=String(D||"").trim().replace("#",""),M=C.length===3?C.split("").map(N=>N+N).join(""):C.padEnd(6,"0").slice(0,6),O=parseInt(M.slice(0,2),16),j=parseInt(M.slice(2,4),16),K=parseInt(M.slice(4,6),16);return[O,j,K]},r=(D=>{let[C,M,O]=n(D);return(.299*C+.587*M+.114*O)/255<.52})(a),p=r?"rgba(255,255,255,0.06)":"#f4f4f5",h=r?"rgba(255,255,255,0.11)":"#e4e4e7",m=r?"rgba(255,255,255,0.08)":"#ffffff",g=r?"rgba(255,255,255,0.18)":"#e4e4e7",b=r?"rgba(255,255,255,0.28)":"#d4d4d8",u=r?"#a1a1aa":"#71717a",v=r?"#71717a":"#a1a1aa",y=r?"#f4f4f5":"#18181b",f=r?"rgba(255,255,255,0.1)":"#f4f4f5",z=r?"#fda4af":"#e11d48",W=r?"rgba(0,0,0,0.45)":"#1e1e1e",U=r?"#e4e4e7":"#d4d4d4",_=r?"rgba(255,255,255,0.08)":"#ffffff",X=r?"#f4f4f5":"#18181b",F=r?"#71717a":"#a1a1aa",q=r?"#f4f4f5":"#18181b",w=d.enableBackdropBlur!==void 0?d.enableBackdropBlur:!1,R=d.backdropBlurAmount||10;return`
    /* ===== \u80CC\u666F\u906E\u7F69\u5C64\uFF08\u5D4C\u5165\u6A21\u5F0F\u6A21\u7CCA\u6548\u679C\uFF09===== */
    .aichathub-backdrop {
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background: rgba(0, 0, 0, ${d.backdropOpacity!==void 0?d.backdropOpacity:.3});
      ${w&&t?`backdrop-filter: blur(${R}px);`:""}
      ${w&&t?`-webkit-backdrop-filter: blur(${R}px);`:""}
      z-index: 2147483000;
      display: ${t&&w?"block":"none"};
      opacity: ${t&&w?"1":"0"};
      transition: opacity 0.3s ease;
      pointer-events: ${t&&w?"auto":"none"};
    }
    .aichathub-backdrop.hidden {
      opacity: 0;
      pointer-events: none;
    }

    /* ===== \u555F\u52D5\u5668\uFF08\u4FDD\u6301\u539F\u8A2D\u8A08\u4F46\u512A\u5316\uFF09===== */
    .aichathub-launcher {
      position: fixed;
      width: 3.5rem;
      height: 3.5rem;
      border-radius: 1.75rem;
      background: ${e};
      color: ${s};
      border: none;
      cursor: pointer;
      display: ${t?"none":"flex"};
      align-items: center;
      justify-content: center;
      font-size: 1.5rem;
      box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15), 0 4px 8px rgba(0,0,0,0.1);
      transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
      z-index: 2147483000;
    }
    .aichathub-launcher[data-position="bottom-right"] { bottom: ${d.bottomOffset}px; right: ${d.rightOffset}px; }
    .aichathub-launcher[data-position="bottom-left"] { bottom: ${d.bottomOffset}px; left: ${d.rightOffset}px; }
    .aichathub-launcher[data-position="top-right"] { top: ${d.bottomOffset}px; right: ${d.rightOffset}px; }
    .aichathub-launcher[data-position="top-left"] { top: ${d.bottomOffset}px; left: ${d.rightOffset}px; }
    .aichathub-launcher:hover { 
      transform: scale(1.05) translateY(-2px);
      box-shadow: 0 12px 32px rgba(0, 0, 0, 0.2);
      background: ${e};
      filter: brightness(0.92);
    }
    .aichathub-launcher.hidden { 
      opacity: 0;
      transform: scale(0.8);
      pointer-events: none;
    }

    /* ===== \u804A\u5929\u9762\u677F ===== */
    .aichathub-panel {
      position: fixed;
      width: ${t?"100%":d.width+"px"};
      ${t?"height: 100%; min-height: 0; max-height: none;":`height: ${d.height}px; max-height: calc(100vh - ${Math.max(0,(d.bottomOffset||24)*2)}px);`}
      background: ${a};
      border-radius: ${t?"0":"16px"};
      box-shadow: ${t?"none":"0 20px 60px rgba(0,0,0,0.16)"};
      display: ${t?"flex":"none"};
      flex-direction: column;
      overflow: hidden;
      z-index: 2147483002;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Roboto", sans-serif;
      color: ${i};
      opacity: ${t?"1":"0"};
      transform: ${t?"none":"scale(0.94) translateY(20px)"};
      transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
      ${t?"top: 0; left: 0; right: 0; bottom: 0;":""}
    }
    .aichathub-panel[data-position="bottom-right"] { bottom: ${d.bottomOffset}px; right: ${d.rightOffset}px; }
    .aichathub-panel[data-position="bottom-left"] { bottom: ${d.bottomOffset}px; left: ${d.rightOffset}px; }
    .aichathub-panel[data-position="top-right"] { top: ${d.bottomOffset}px; right: ${d.rightOffset}px; }
    .aichathub-panel[data-position="top-left"] { top: ${d.bottomOffset}px; left: ${d.rightOffset}px; }
    .aichathub-panel.open { 
      display: flex;
      opacity: 1;
      transform: scale(1) translateY(0);
    }

    /* ===== \u6A19\u984C\u5217\uFF08\u5C0D\u9F4A Chat \u9801\u9762\uFF09===== */
    .aichathub-header {
      background: ${e};
      color: ${o};
      height: 3.5rem;
      padding: 0 1rem;
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-shrink: 0;
      border-bottom: 1px solid rgba(255,255,255,0.18);
    }
    .aichathub-header-actions {
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .aichathub-title {
      font-size: 0.875rem;
      font-weight: 600;
      color: ${o};
    }
    .aichathub-header-btn {
      background: transparent;
      border: none;
      color: ${o};
      padding: 0.375rem 0.75rem;
      border-radius: 0.25rem;
      cursor: pointer;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 16px;
    }
    .aichathub-header-btn:hover { 
      background: rgba(255,255,255,0.16);
      color: ${o};
      transform: scale(1.05);
    }
    .aichathub-header-btn:active { 
      transform: scale(0.95);
    }
    .aichathub-header-btn svg {
      width: 16px;
      height: 16px;
    }
    .aichathub-expand {
      display: ${t?"none":"flex"};
    }
    .aichathub-minimize {
      display: ${t?"flex":"none"};
    }
    .aichathub-close {
      display: ${t?"none":"flex"};
    }

    /* ===== \u5167\u5BB9\u5340\u57DF ===== */
    .aichathub-body { 
      padding: 1rem 0 0.5rem 0; 
      flex: 1 1 auto; 
      overflow-y: auto; 
      background: ${a};
      min-height: 0;
    }
    .aichathub-body::-webkit-scrollbar {
      width: 5px;
    }
    .aichathub-body::-webkit-scrollbar-track {
      background: transparent;
    }
    .aichathub-body::-webkit-scrollbar-thumb {
      background: rgba(113, 113, 122, 0.3);
      border-radius: 2.5px;
    }
    .aichathub-body::-webkit-scrollbar-thumb:hover {
      background: rgba(113, 113, 122, 0.5);
    }

    /* ===== \u7A7A\u767D\u72C0\u614B ===== */
    .aichathub-empty-state {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      height: 100%;
      text-align: center;
      padding: 1.25rem;
    }
    .aichathub-empty-icon {
      font-size: 3rem;
      color: ${b};
      margin-bottom: 1rem;
    }
    .aichathub-empty-text {
      font-size: 0.875rem;
      color: ${u};
      line-height: 1.5;
    }

    /* ===== Typing Indicator \u52D5\u756B ===== */
    .aichathub-typing {
      padding: 12px 0 !important;
      max-width: 80px !important;
      margin-left: 12px !important;
    }
    .aichathub-typing-dots {
      display: flex;
      align-items: center;
      gap: 6px;
      padding: 8px 0;
    }
    .aichathub-typing-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: ${v};
      animation: aichathub-typing-bounce 1.4s infinite ease-in-out;
    }
    .aichathub-typing-dot:nth-child(1) {
      animation-delay: 0s;
    }
    .aichathub-typing-dot:nth-child(2) {
      animation-delay: 0.2s;
    }
    .aichathub-typing-dot:nth-child(3) {
      animation-delay: 0.4s;
    }
    @keyframes aichathub-typing-bounce {
      0%, 60%, 100% {
        transform: translateY(0);
        opacity: 0.7;
      }
      30% {
        transform: translateY(-10px);
        opacity: 1;
      }
    }

    /* ===== \u8A0A\u606F\u6C23\u6CE1 ===== */
    .aichathub-msg { 
      word-break: break-word;
      line-height: 1.5;
      font-size: 14px;
      animation: slideIn 0.3s ease-out;
      transition: background-color 0.2s ease;
      margin-bottom: 8px;
    }
    @keyframes slideIn {
      from { opacity: 0; transform: translateY(10px); }
      to { opacity: 1; transform: translateY(0); }
    }
    
    /* \u7528\u6236\u8A0A\u606F - \u5C0D\u8A71\u6846\u6A23\u5F0F\uFF08\u5C0D\u9F4A Chat \u9801\u9762\uFF09 */
    .aichathub-msg-user { 
      display: flex;
      justify-content: flex-end;
      padding: 0.75rem 1rem;
    }
    .aichathub-msg-user > div {
      max-width: 32rem;
      background: ${e};
      color: ${s};
      border-radius: 1rem;
      padding: 0.75rem 1rem;
      font-size: 0.875rem;
      box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
    }
    .aichathub-msg-user .aichathub-msg-time {
      color: #a1a1aa;
      opacity: 0.7;
    }
    
    /* AI \u8A0A\u606F - ChatGPT \u6D41\u5F0F\u6A23\u5F0F\uFF08\u5C0D\u9F4A Chat \u9801\u9762\uFF09 */
    .aichathub-msg-assistant { 
      background: transparent;
      color: ${i};
      padding: 1rem;
      margin: 0;
      border-radius: 0;
    }
    .aichathub-msg-assistant:hover {
      background: transparent;
    }
    
    .aichathub-msg-time {
      font-size: 11px;
      color: ${v};
      margin-top: 6px;
      opacity: 0.8;
    }

    /* ===== Markdown \u5167\u5BB9\u6A23\u5F0F ===== */
    .markdown-content {
      line-height: 1.7;
      font-size: 14px;
    }
    .markdown-content p {
      margin: 0.75em 0;
    }
    .markdown-content p:first-child {
      margin-top: 0;
    }
    .markdown-content p:last-child {
      margin-bottom: 0;
    }
    .markdown-content h1,
    .markdown-content h2,
    .markdown-content h3,
    .markdown-content h4,
    .markdown-content h5,
    .markdown-content h6 {
      margin: 1.25em 0 0.75em 0;
      font-weight: 600;
      line-height: 1.3;
      color: ${y};
    }
    .markdown-content h1 {
      font-size: 1.5em;
    }
    .markdown-content h2 {
      font-size: 1.3em;
    }
    .markdown-content h3 {
      font-size: 1.1em;
    }
    .markdown-content h4 {
      font-size: 1em;
    }
    .markdown-content ul,
    .markdown-content ol {
      margin: 0.75em 0;
      padding-left: 1.5em;
    }
    .markdown-content li {
      margin: 0.25em 0;
    }
    .markdown-content code {
      background: ${f};
      padding: 0.15em 0.4em;
      border-radius: 3px;
      font-size: 0.9em;
      font-family: 'Consolas', 'Monaco', 'Courier New', monospace;
      color: ${z};
    }
    .markdown-content pre {
      background: ${W};
      color: ${U};
      padding: 1em;
      border-radius: 6px;
      overflow-x: auto;
      margin: 1em 0;
    }
    .markdown-content pre code {
      background: transparent;
      padding: 0;
      color: inherit;
      font-size: 0.875em;
      line-height: 1.6;
    }
    .markdown-content blockquote {
      border-left: 3px solid ${g};
      padding-left: 1em;
      margin: 1em 0;
      color: ${u};
      font-style: italic;
    }
    .markdown-content table {
      border-collapse: collapse;
      width: 100%;
      margin: 1em 0;
      font-size: 0.9em;
    }
    .markdown-content table th,
    .markdown-content table td {
      border: 1px solid ${g};
      padding: 0.5em 0.75em;
      text-align: left;
    }
    .markdown-content table th {
      background: ${p};
      font-weight: 600;
    }
    .markdown-content table tr:nth-child(even) {
      background: ${r?"rgba(255,255,255,0.03)":"#fafafa"};
    }
    .markdown-content a {
      color: #2563eb;
      text-decoration: underline;
    }
    .markdown-content a:hover {
      color: #1d4ed8;
    }
    .markdown-content hr {
      border: none;
      border-top: 1px solid ${g};
      margin: 1.5em 0;
    }
    .markdown-content img {
      max-width: 100%;
      height: auto;
      border-radius: 4px;
      margin: 0.5em 0;
    }

    /* ===== \u8A0A\u606F\u64CD\u4F5C\u6309\u9215 ===== */
    .aichathub-msg-actions {
      display: flex;
      align-items: center;
      gap: 0.25rem;
      margin-top: 0.75rem;
      padding-top: 0.75rem;
      border-top: 1px solid ${g};
    }
    .aichathub-action-btn {
      background: transparent;
      border: none;
      cursor: pointer;
      font-size: 0.75rem;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
      padding: 0.375rem;
      border-radius: 0.25rem;
      color: ${u};
      display: inline-flex;
      align-items: center;
      justify-content: center;
    }
    .aichathub-action-btn:hover { 
      background: ${p};
      color: ${q};
      transform: scale(1.05);
    }
    .aichathub-action-btn:active { 
      transform: scale(0.95);
    }

    /* ===== \u5167\u5BB9\u5305\u88DD\u5668 ===== */
    .aichathub-content-wrapper {
      position: relative;
      flex: 1;
      display: flex;
      flex-direction: column;
      overflow: hidden;
      min-height: 0;
    }
    
    /* ===== \u8F38\u5165\u5340\u57DF\uFF08\u52D5\u614B\u5CF6\u6A23\u5F0F\uFF09===== */
    .aichathub-input-container { 
      position: relative;
      padding: 0.5rem 0.75rem 0.75rem 0.75rem;
      background: transparent;
      flex-shrink: 0;
      z-index: 10;
      display: flex;
      flex-direction: column;
    }
    
    /* ===== AI \u5EFA\u8B70\u6A19\u7C64 ===== */
    .aichathub-tags-container {
      position: relative;
      width: 100%;
      padding: 0;
      margin-bottom: 0.5rem;
    }
    
    .aichathub-tags-scroll {
      display: flex;
      gap: 0.5rem;
      overflow-x: auto;
      overflow-y: hidden;
      padding: 0.25rem 1.75rem;
      scroll-behavior: smooth;
      -ms-overflow-style: none;
      scrollbar-width: none;
    }
    
    .aichathub-tags-scroll::-webkit-scrollbar {
      display: none;
    }
    
    .aichathub-tag-scroll-btn {
      position: absolute;
      top: 50%;
      transform: translateY(-50%);
      width: 32px;
      height: 32px;
      background: ${m};
      border: 1px solid ${g};
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
      z-index: 10;
      color: ${u};
      box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    }
    
    .aichathub-tag-scroll-btn:hover {
      background: ${p};
      border-color: ${b};
      transform: translateY(-50%) scale(1.05);
    }
    
    .aichathub-tag-scroll-left {
      left: 0;
    }
    
    .aichathub-tag-scroll-right {
      right: 0;
    }
    
    .aichathub-tag-btn {
      background: ${p};
      border: 2px solid ${b};
      border-radius: 1rem;
      padding: 0.375rem 0.75rem;
      font-size: 0.8125rem;
      color: ${i};
      cursor: pointer;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
      font-family: inherit;
      white-space: nowrap;
      flex-shrink: 0;
      box-shadow: none;
    }
    
    .aichathub-tag-btn:hover {
      background: ${h};
      border-color: ${r?"rgba(255,255,255,0.35)":"#a1a1aa"};
      color: ${y};
    }
    
    .aichathub-tag-btn:active {
      transform: scale(0.98);
    }
    
    .aichathub-tag-loading {
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 0.5rem;
      color: ${u};
      font-size: 0.8125rem;
    }
    
    .aichathub-tag-loading-spinner {
      width: 14px;
      height: 14px;
      border: 2px solid ${g};
      border-top-color: ${u};
      border-radius: 50%;
      animation: aichathub-spin 0.6s linear infinite;
      margin-right: 0.5rem;
    }
    
    @keyframes aichathub-spin {
      to { transform: rotate(360deg); }
    }
    
    .aichathub-input-wrapper {
      position: relative;
      display: block;
    }
    
    .aichathub-input { 
      width: 100%;
      border: 1px solid ${b};
      border-radius: 1.75rem; 
      padding: 14px 64px 14px 24px;
      font-size: 14px;
      resize: none;
      background: ${_};
      color: ${X};
      font-family: inherit;
      line-height: 24px;
      max-height: 200px;
      min-height: 52px;
      height: 52px;
      overflow: hidden;
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
      box-sizing: border-box;
    }
    .aichathub-input::placeholder {
      color: ${F};
    }
    .aichathub-input:hover:not(:focus) {
      border-color: ${r?"rgba(255,255,255,0.38)":"#a1a1aa"};
    }
    .aichathub-input:focus { 
      outline: none;
      border-color: ${r?"#a1a1aa":"#71717a"};
    }
    .aichathub-send-btn { 
      position: absolute;
      right: 4px;
      bottom: 8px;
      background: ${e};
      color: ${s}; 
      border: none; 
      border-radius: 1.375rem; 
      width: 44px;
      height: 44px;
      cursor: pointer; 
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
    }
    .aichathub-send-btn svg {
      width: 1rem;
      height: 1rem;
    }
    .aichathub-send-btn:hover { 
      background: ${e};
      filter: brightness(0.92);
      transform: scale(1.05);
      box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.15), 0 10px 10px -5px rgba(0, 0, 0, 0.08);
    } 
    .aichathub-send-btn:active {
      transform: scale(0.95);
    }
    .aichathub-send-btn:disabled {
      opacity: 0.5; 
      cursor: not-allowed;
    }

    .aichathub-panel.expanded{position:fixed!important;width:calc(100vw - 40px)!important;height:calc(100vh - 40px)!important;max-width:100vw!important;max-height:100vh!important;top:20px!important;right:20px!important;bottom:auto!important;left:auto!important;border-radius:16px!important;box-shadow:0 25px 50px -12px rgba(0,0,0,0.5)!important;z-index:2147483645!important;animation:aichathub-expand-in .3s ease-out}@keyframes aichathub-expand-in{from{opacity:0;transform:scale(.95)}to{opacity:1;transform:scale(1)}}.aichathub-panel.expanded{position:fixed!important;width:calc(100vw - 40px)!important;height:calc(100vh - 40px)!important;max-width:100vw!important;max-height:100vh!important;top:20px!important;right:20px!important;bottom:auto!important;left:auto!important;border-radius:16px!important;box-shadow:0 25px 50px -12px rgba(0,0,0,0.5)!important;z-index:2147483645!important;animation:aichathub-expand-in .3s ease-out}@keyframes aichathub-expand-in{from{opacity:0;transform:scale(.95)}to{opacity:1;transform:scale(1)}}@media (max-width: ${d.mobileBreakpoint||768.aichathub-panel.expanded{width:100vw!important;height:100vh!important;top:0!important;right:0!important;bottom:0!important;left:0!important;border-radius:0!important}.aichathub-panel.expanded{width:100vw!important;height:100vh!important;top:0!important;right:0!important;bottom:0!important;left:0!important;border-radius:0!important;}}px) {
      .aichathub-launcher[data-position="bottom-right"],
      .aichathub-launcher[data-position="bottom-left"] {
        bottom: 16px;
      }
      .aichathub-launcher[data-position="bottom-right"],
      .aichathub-panel[data-position="bottom-right"] {
        right: 16px;
      }
      .aichathub-launcher[data-position="bottom-left"],
      .aichathub-panel[data-position="bottom-left"] {
        left: 16px;
      }
      .aichathub-panel {
        width: calc(100vw - 16px) !important;
        height: calc(100vh - 16px) !important;
        max-height: calc(100vh - 16px) !important;
        bottom: 8px !important;
        top: auto !important;
        border-radius: 12px;
      }
      .aichathub-panel.open {
        transform: translateY(0);
      }
      .aichathub-input-container {
        padding: 0.5rem;
      }
      .aichathub-input {
        padding: 12px 56px 12px 16px;
      }
      .aichathub-send-btn {
        width: 40px;
        height: 40px;
        bottom: 6px;
      }
    }

    /* ===== \u8F09\u5165\u52D5\u756B ===== */
    @keyframes pulse {
      0%, 100% { opacity: 1; }
      50% { opacity: 0.5; }
    }
    .aichathub-loading {
      display: inline-flex;
      gap: 4px;
      padding: 8px 0;
    }
    .aichathub-loading-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: currentColor;
      animation: pulse 1.4s infinite;
    }
    .aichathub-loading-dot:nth-child(2) { animation-delay: 0.2s; }
    .aichathub-loading-dot:nth-child(3) { animation-delay: 0.4s; }
  `}function P(d,t){let a="aichathub-widget-styles",e=document.getElementById(a);e&&e.remove();let o=document.createElement("style");o.id=a,o.textContent=V(d,t),document.head.appendChild(o)}var B=class{constructor(t){this.launcher=null;this.conversationId=null;this.backdropElement=null;console.log("[AIChatHub Widget] \u958B\u59CB\u521D\u59CB\u5316",t),this.config={assistantName:"AI \u52A9\u624B",welcomeMessage:"\u60A8\u597D\uFF01\u6709\u4EC0\u9EBC\u53EF\u4EE5\u5E6B\u52A9\u60A8\u7684\u55CE\uFF1F",position:"bottom-right",width:420,height:650,bottomOffset:24,rightOffset:24,mobileBreakpoint:768,enableAnalytics:!0,enableMessageCopy:!0,enableMessageRating:!0,supportDarkMode:!1,allowDraggable:!1,persistHistory:!0,messageDebounceMs:300,maxHistoryMessages:100,openByDefault:!1,enableBackdropBlur:!1,backdropBlurAmount:10,backdropOpacity:.3,...t},this.isEmbedded=!1,console.log("[AIChatHub Widget] \u4F7F\u7528\u6A21\u5F0F: Popup"),this.apiService=new k(this.config),this.storageService=new E(this.config.projectId),this.conversationId=this.config.conversationId||null,console.log("[AIChatHub Widget] \u670D\u52D9\u521D\u59CB\u5316\u5B8C\u6210\uFF0CconversationId:",this.conversationId),P(this.config,this.isEmbedded),this.isEmbedded||(console.log("[AIChatHub Widget] \u5275\u5EFA Launcher \u5143\u4EF6"),this.launcher=new I(this.config),console.log("[AIChatHub Widget] Launcher \u5143\u4EF6\u5275\u5EFA\u5B8C\u6210")),console.log("[AIChatHub Widget] \u5275\u5EFA Panel \u5143\u4EF6"),this.panel=new $(this.config,this.isEmbedded),console.log("[AIChatHub Widget] Panel \u5143\u4EF6\u5275\u5EFA\u5B8C\u6210"),console.log("[AIChatHub Widget] \u958B\u59CB\u8A2D\u7F6E\u4E8B\u4EF6"),this.setupEvents(),console.log("[AIChatHub Widget] \u4E8B\u4EF6\u8A2D\u7F6E\u5B8C\u6210"),console.log("[AIChatHub Widget] \u958B\u59CB\u6E32\u67D3\u5230 DOM"),this.render(),console.log("[AIChatHub Widget] DOM \u6E32\u67D3\u5B8C\u6210"),this.config.persistHistory&&this.loadHistory(),this.loadSuggestedTags(),(this.isEmbedded||this.config.openByDefault)&&this.panel.open(),this.apiService.sendAnalyticsEvent("widget_initialized"),this.setupConfigUpdateListener()}setupConfigUpdateListener(){window.addEventListener("message",t=>{t.data&&t.data.type==="UPDATE_CONFIG"&&(console.log("[AIChatHub Widget] \u6536\u5230\u914D\u7F6E\u66F4\u65B0\u6D88\u606F:",t.data.config),this.updateConfig(t.data.config))})}updateConfig(t){console.log("[updateConfig] \u958B\u59CB\u66F4\u65B0\u914D\u7F6E\uFF0C\u65B0\u914D\u7F6E:",t),this.config={...this.config,...t},console.log("[updateConfig] \u5408\u4F75\u5F8C\u7684\u5B8C\u6574\u914D\u7F6E:",this.config),console.log("[updateConfig] \u91CD\u65B0\u6CE8\u5165\u6A23\u5F0F"),P(this.config,this.isEmbedded),t.assistantName&&(console.log("[updateConfig] \u66F4\u65B0\u9762\u677F\u6A19\u984C:",t.assistantName),this.panel.updateTitle(t.assistantName)),t.welcomeMessage&&(console.log("[updateConfig] \u66F4\u65B0\u6B61\u8FCE\u8A0A\u606F:",t.welcomeMessage),this.panel.getMessageList().updateWelcomeMessage(t.welcomeMessage)),this.apiService=new k(this.config),console.log("[updateConfig] \u914D\u7F6E\u66F4\u65B0\u5B8C\u6210")}setupEvents(){console.log("[AIChatHub Widget] setupEvents - \u958B\u59CB\u8A2D\u7F6E\u4E8B\u4EF6\u8655\u7406\u5668"),this.launcher?(console.log("[AIChatHub Widget] setupEvents - \u8A2D\u7F6E Launcher \u9EDE\u64CA\u4E8B\u4EF6"),this.launcher.onClick(()=>{console.log("[AIChatHub Widget] Launcher \u88AB\u9EDE\u64CA\uFF01"),this.togglePanel()})):console.log("[AIChatHub Widget] setupEvents - Launcher \u4E0D\u5B58\u5728\uFF0C\u8DF3\u904E\u9EDE\u64CA\u4E8B\u4EF6\u8A2D\u7F6E"),document.addEventListener("keydown",t=>{t.key==="Escape"&&this.panel.isOpen()&&!document.querySelector(".aichathub-report-modal")&&(this.close(),this.apiService.sendAnalyticsEvent("widget_closed_by_escape"))}),this.panel.getInput().onSend(t=>{this.sendMessage(t)}),this.panel.getInput().onTagClick(t=>{this.panel.getInput().setValue(t),this.sendMessage(t)}),this.panel.onClear(()=>{this.clearConversation()}),this.isEmbedded||this.panel.onClose(()=>{this.launcher?.show(),this.apiService.sendAnalyticsEvent("widget_closed")})}render(){if(console.log("[AIChatHub Widget] render - \u958B\u59CB\u6E32\u67D3\u5143\u4EF6"),!document.body){console.error("[AIChatHub Widget] render - document.body \u4E0D\u5B58\u5728\uFF0C\u7121\u6CD5\u6E32\u67D3");return}if(console.log("[AIChatHub Widget] render - document.body \u5B58\u5728"),this.isEmbedded&&this.config.enableBackdropBlur&&(console.log("[AIChatHub Widget] render - \u5275\u5EFA\u80CC\u666F\u906E\u7F69\u5C64"),this.backdropElement=document.createElement("div"),this.backdropElement.className="aichathub-backdrop",document.body.appendChild(this.backdropElement),console.log("[AIChatHub Widget] render - \u80CC\u666F\u906E\u7F69\u5C64\u5DF2\u6DFB\u52A0\u5230 DOM")),this.launcher){console.log("[AIChatHub Widget] render - \u6E96\u5099\u6E32\u67D3 Launcher");let a=this.launcher.getElement();a?(console.log("[AIChatHub Widget] render - Launcher element \u5B58\u5728\uFF0C\u6DFB\u52A0\u5230 body"),document.body.appendChild(a),console.log("[AIChatHub Widget] render - Launcher \u5DF2\u6DFB\u52A0\u5230 DOM")):console.error("[AIChatHub Widget] render - launcher element \u4E0D\u5B58\u5728")}else console.log("[AIChatHub Widget] render - \u7121 Launcher (embedded \u6A21\u5F0F)");console.log("[AIChatHub Widget] render - \u6E96\u5099\u6E32\u67D3 Panel");let t=this.panel?.getElement();t?(console.log("[AIChatHub Widget] render - Panel element \u5B58\u5728\uFF0C\u6DFB\u52A0\u5230 body"),document.body.appendChild(t),console.log("[AIChatHub Widget] render - Panel \u5DF2\u6DFB\u52A0\u5230 DOM\uFF0CclassList:",t.classList.toString())):console.error("[AIChatHub Widget] render - panel element \u4E0D\u5B58\u5728\uFF0C\u7121\u6CD5\u6E32\u67D3")}togglePanel(){console.log("[AIChatHub Widget] togglePanel - \u88AB\u8ABF\u7528"),console.log("[AIChatHub Widget] togglePanel - \u7576\u524D\u9762\u677F\u72C0\u614B:",this.panel.isOpen()?"\u958B\u555F":"\u95DC\u9589"),this.panel.isOpen()?(console.log("[AIChatHub Widget] togglePanel - \u95DC\u9589\u9762\u677F"),this.panel.close(),this.launcher?.show(),console.log("[AIChatHub Widget] togglePanel - Launcher \u986F\u793A"),this.apiService.sendAnalyticsEvent("widget_closed")):(console.log("[AIChatHub Widget] togglePanel - \u958B\u555F\u9762\u677F"),this.panel.open(),console.log("[AIChatHub Widget] togglePanel - \u9762\u677F open() \u5DF2\u8ABF\u7528"),this.launcher?.hide(),console.log("[AIChatHub Widget] togglePanel - Launcher \u96B1\u85CF"),this.apiService.sendAnalyticsEvent("widget_opened")),console.log("[AIChatHub Widget] togglePanel - \u5B8C\u6210\uFF0C\u65B0\u72C0\u614B:",this.panel.isOpen()?"\u958B\u555F":"\u95DC\u9589")}async sendMessage(t){let e={id:`msg_${Date.now()}_${Math.random().toString(36).substr(2,9)}`,role:"user",content:t,timestamp:Date.now()};this.panel.getMessageList().addMessage(e),this.panel.getInput().clear(),this.panel.getInput().setDisabled(!0),this.config.persistHistory&&this.saveHistory(),this.panel.getMessageList().showTypingIndicator();try{let o=await this.apiService.sendMessage(t,this.conversationId);this.panel.getMessageList().hideTypingIndicator(),o.conversationHistoryId&&(this.conversationId=o.conversationHistoryId,console.log("[sendMessage] \u66F4\u65B0 conversationId:",this.conversationId));let i={id:o.messageId||`msg_${Date.now()}_${Math.random().toString(36).substr(2,9)}`,role:"assistant",content:o.message,timestamp:Date.now()};this.panel.getMessageList().addMessage(i,(s,n)=>this.regenerateMessage(s,n),(s,n,l)=>this.submitFeedback(s,n,l)),this.config.persistHistory&&this.saveHistory(),this.apiService.sendAnalyticsEvent("message_sent",{length:t.length}),this.loadSuggestedTags()}catch(o){console.error("Failed to send message:",o),this.panel.getMessageList().hideTypingIndicator();let i={id:`error_${Date.now()}`,role:"error",content:"抱歉，目前連線不穩定，請稍後重試。若持續發生，請檢查網路或重新整理頁面。",timestamp:Date.now()};this.panel.getMessageList().addMessage(i)}finally{this.panel.getInput().setDisabled(!1),this.panel.getInput().focus()}}async regenerateMessage(t,a){this.panel.getMessageList().removeMessage(t),await this.sendMessage(a)}async submitFeedback(t,a,e){try{await this.apiService.submitFeedback(t,a,e),console.log("[Widget] \u53CD\u994B\u5DF2\u63D0\u4EA4:",t,a,e),this.apiService.sendAnalyticsEvent("feedback_submitted",{feedbackType:a})}catch(o){console.error("[Widget] \u63D0\u4EA4\u53CD\u994B\u5931\u6557:",o),this.panel.getMessageList().showToast("提交回饋失敗，請稍後再試。")}}clearConversation(){this.panel.getMessageList().clear(),this.loadSuggestedTags()}async loadSuggestedTags(){try{this.panel.getInput().setTagsLoading();let[t]=await Promise.all([this.apiService.getSuggestedTags(this.conversationId,this.panel.getInput().getValue()),new Promise(a=>setTimeout(a,300))]);this.panel.getInput().setTags(t)}catch(t){console.error("[Widget] \u8F09\u5165\u5EFA\u8B70\u6A19\u7C64\u5931\u6557:",t),this.panel.getInput().clearTags()}}loadHistory(){let t=this.storageService.loadMessages();t.length>0&&this.panel.getMessageList().loadMessages(t,(a,e)=>this.regenerateMessage(a,e),(a,e,o)=>this.submitFeedback(a,e,o))}saveHistory(){let t=this.panel.getMessageList().getMessages();this.storageService.saveMessages(t)}open(){this.panel.open(),this.launcher?.hide()}close(){this.panel.close(),this.launcher?.show()}destroy(){this.launcher?.getElement().remove(),this.panel.getElement().remove();let t=document.getElementById("aichathub-widget-styles");t&&t.remove()}};window.initAIChatHubWidget=function(d){if(console.log("[AIChatHub Widget] initAIChatHubWidget \u88AB\u8ABF\u7528\uFF0C\u914D\u7F6E:",d),!d||!d.projectId)return console.error("[AIChatHub Widget] \u521D\u59CB\u5316\u5931\u6557 - projectId \u7F3A\u5931"),null;console.log("[AIChatHub Widget] \u914D\u7F6E\u9A57\u8B49\u901A\u904E\uFF0C\u958B\u59CB\u5275\u5EFA Widget \u5BE6\u4F8B");let t=new B(d);return console.log("[AIChatHub Widget] Widget \u5BE6\u4F8B\u5275\u5EFA\u5B8C\u6210"),t};console.log("[AIChatHub Widget] \u6AA2\u67E5\u81EA\u52D5\u521D\u59CB\u5316\u914D\u7F6E...");var T=window.AIChatHubConfig||window.aiChatHubConfig;console.log("[AIChatHub Widget] \u81EA\u52D5\u914D\u7F6E:",T);console.log("[AIChatHub Widget] document.readyState:",document.readyState);typeof T<"u"?(console.log("[AIChatHub Widget] \u627E\u5230\u81EA\u52D5\u914D\u7F6E\uFF0C\u6E96\u5099\u521D\u59CB\u5316"),document.readyState==="loading"?(console.log("[AIChatHub Widget] DOM \u5C1A\u672A\u8F09\u5165\uFF0C\u76E3\u807D DOMContentLoaded"),document.addEventListener("DOMContentLoaded",()=>{console.log("[AIChatHub Widget] \u81EA\u52D5\u521D\u59CB\u5316 (DOMContentLoaded)\uFF0C\u914D\u7F6E:",T),window.initAIChatHubWidget(T)})):(console.log("[AIChatHub Widget] DOM \u5DF2\u8F09\u5165\uFF0C\u7ACB\u5373\u521D\u59CB\u5316"),window.initAIChatHubWidget(T))):console.log("[AIChatHub Widget] \u672A\u627E\u5230\u81EA\u52D5\u914D\u7F6E\uFF0C\u9700\u8981\u624B\u52D5\u521D\u59CB\u5316");var yt=B;})();
