(function(root){
'use strict';
function list(state,{dimension='o',kind='all',query=''}={}){
 const signs=(state.signs||[]).map(s=>({...s,kind:'sign'}));
 const chests=state.chests.map(c=>({...c,dimension:c.dimension||'o',kind:'chest',name:root.DemoCore.chestName(c)}));
 const markers=state.markers.map((m,i)=>({...m,id:'marker:'+i,dimension:m.dimension||'o',kind:'marker'}));
 const terms=query.toLocaleLowerCase().trim().split(/\s+/).filter(Boolean);
 return [...signs,...chests,...markers].filter(p=>p.dimension===dimension&&(kind==='all'||p.kind===kind)&&terms.every(t=>[p.name||'',p.readable?p.text||'':'',`${p.x} ${p.y??''} ${p.z}`].join(' ').toLocaleLowerCase().includes(t))).sort((a,b)=>a.kind.localeCompare(b.kind)||a.x-b.x||a.z-b.z||(a.y??0)-(b.y??0)||a.id.localeCompare(b.id));
}
function advance(index,delta,length){return length?((index+delta)%length+length)%length:-1;}
function mount(container,state,dimension,onSelect,{selectFirst=true}={}){
 container.innerHTML=I18n.html`<h2>Interessante Punkte</h2><div class="toolbar"><select id="point-kind" aria-label="Interessante Punkte"><option value="all">Alle Punkte</option><option value="sign">Schilder</option><option value="chest">Kisten</option><option value="marker">Eigene Markierungen</option></select><input id="point-search" type="search" placeholder="Punkte durchsuchen …" aria-label="Punkte durchsuchen …"></div><div class="point-nav"><button id="point-prev" aria-label="Vorheriger Punkt">←</button><span id="point-count" role="status"></span><button id="point-next" aria-label="Nächster Punkt">→</button></div><div id="point-detail" aria-live="polite"></div><p class="small">Beschriftungen werden unverändert angezeigt.</p>`;
 const $=selector=>container.querySelector(selector);let results=[],index=0;
 if((state.signs||[]).some(s=>s.dimension===dimension))$('#point-kind').value='sign';
 function show(select=true){
 const p=results[index];$('#point-prev').disabled=$('#point-next').disabled=!p;$('#point-count').textContent=p?`${index+1} / ${results.length}`:I18n.t('Keine passenden Punkte.');const detail=$('#point-detail');detail.replaceChildren();if(!p)return;
 const title=document.createElement('strong');title.textContent=p.kind==='sign'?I18n.t('Schild'):p.name;const coords=document.createElement('p');coords.className='coordinates';coords.textContent=`X ${p.x} · Y ${p.y??'—'} · Z ${p.z}`;detail.append(title,coords);
 if(p.kind==='sign'){const text=document.createElement('pre');text.className='sign-text';text.textContent=p.readable?(p.text||I18n.t('Leere Beschriftung')):I18n.t('Beschriftung nicht verfügbar');detail.append(text);}
 if(select)onSelect(p);
 }
 function refresh(select=true){results=list(state,{dimension,kind:$('#point-kind').value,query:$('#point-search').value});index=0;show(select);}
 $('#point-kind').onchange=()=>refresh();$('#point-search').oninput=()=>refresh();$('#point-prev').onclick=()=>{index=advance(index,-1,results.length);show();};$('#point-next').onclick=()=>{index=advance(index,1,results.length);show();};refresh(selectFirst);return {refresh};
}
const api={list,advance,mount};root.Points=api;if(typeof module!=='undefined')module.exports=api;
})(globalThis);
