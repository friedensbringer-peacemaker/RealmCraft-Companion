'use strict';
(function(){
const strip=document.createElement('section');strip.className='source-bar';strip.setAttribute('aria-label',I18n.t('Datenquelle'));
strip.innerHTML=I18n.t('<div><span class="eyebrow">DATENQUELLE</span><strong id="source-name">Synthetische Beispieldaten</strong><span id="source-detail" class="small">Keine ZIP geladen</span></div><div class="toolbar"><button id="load-demo" class="primary">Demo-ZIP laden</button><button id="open-zip">Eigene ZIP öffnen …</button><input id="zip-file" type="file" accept=".zip,application/zip" hidden></div>');
$('.topbar').after(strip);
const dialog=document.createElement('dialog');dialog.id='import-dialog';dialog.innerHTML=I18n.t('<h2>Spielstand-ZIP öffnen</h2><p class="small">Die Datei wird nur in diesem Browser gelesen. Sie wird nicht hochgeladen oder verändert.</p><p id="import-status" role="status" aria-live="polite"></p><progress id="import-progress" max="100" value="0" hidden></progress><div id="import-worlds"></div><p class="small">Ein erfolgreicher Import ersetzt die aktuelle Ansicht und ihre Sitzungsänderungen. Bei einem Fehler bleibt der bisherige Datenstand erhalten.</p><div class="toolbar"><button id="cancel-import">Abbrechen</button><button id="confirm-import" class="primary" hidden>Ausgewählte Welt öffnen</button></div>');document.body.append(dialog);
const dialogOriginals=[...dialog.querySelectorAll('h2,p.small,button')].map(node=>[node,reverseUI(node.textContent)]);
function refreshDialog(){for(const [node,text] of dialogOriginals)node.textContent=I18n.t(text);}
function reverseUI(text){const entries=Object.entries(I18n.pairs).sort((a,b)=>b[1].length-a[1].length);const exact=entries.find(([,en])=>en===text);return exact?exact[0]:text;}
let worker=null,sourceName='',sourceKind='local',abort=null;
const status=message=>{$('#import-status').textContent=I18n.t(message);if(awaitingDemo){demoLoadMessage=message;render();}};
function cleanup(){worker?.terminate();worker=null;abort?.abort();abort=null;$('#zip-file').value='';}
function cancel(){cleanup();if(awaitingDemo)status('Laden abgebrochen.');}
dialog.addEventListener('cancel',cancel);$('#cancel-import').onclick=()=>{cancel();dialog.close();};
function begin(){refreshDialog();cleanup();$('#import-worlds').replaceChildren();$('#confirm-import').hidden=true;$('#import-progress').hidden=true;status(I18n.t('ZIP wird geprüft …'));if(!dialog.open)dialog.showModal();}
function inspect(file,kind){
 sourceName=file.name;sourceKind=kind;
 worker=new Worker('import-worker.js');const activeWorker=worker;
 worker.onerror=()=>{if(worker!==activeWorker)return;cleanup();status(I18n.t('Der Import konnte nicht gestartet werden. Bitte Seite neu laden und einen aktuellen Browser verwenden.'));};
 worker.onmessage=async({data})=>{
  if(worker!==activeWorker)return;
  if(data.type==='worlds'){
   if(kind==='demo'&&data.worlds.length===1){$('#import-progress').hidden=false;status('Welt wird eingelesen …');worker.postMessage({action:'load',prefix:data.worlds[0].prefix});return;}
   status(I18n.html`${data.worlds.length} Welt(en) gefunden. Bitte auswählen.`);const list=$('#import-worlds');
   data.worlds.forEach((w,i)=>{const label=document.createElement('label');label.className='world-choice';const input=document.createElement('input');input.type='radio';input.name='import-world';input.value=w.prefix;input.checked=i===0;const text=document.createElement('span');text.textContent=I18n.html`${w.name} · ${w.chunks} Chunks · ID ${w.worldID}`;label.append(input,text);list.append(label);});$('#confirm-import').hidden=false;
  }else if(data.type==='progress'){$('#import-progress').value=data.done/data.total*100;status(I18n.html`Karte und Kisten lesen: ${data.done} / ${data.total} Chunks`);}
  else if(data.type==='error'){status(data.message);$('#confirm-import').hidden=true;$('#import-progress').hidden=true;cleanup();}
  else if(data.type==='loaded'){
   try{
    status(I18n.t('Katalog und Ansichten vorbereiten …'));const catalog=await getData('WorldCatalog');if(!dialog.open||worker!==activeWorker)return;
    const next=C.fromImport(data.result,catalog,{kind:sourceKind,filename:sourceName});
    state=next;awaitingDemo=false;undo=[];selectedSlot=0;transfer=null;mapFocus=null;window.ImportedMap?.reset();
    $('#source-name').textContent=next.source.name;$('#source-detail').textContent=I18n.html`${sourceKind==='demo'?I18n.t('Bereitgestellte Demo'):I18n.t('Lokale ZIP')} · ${Object.values(next.worldMap.dimensions).reduce((n,d)=>n+d.chunks.length,0)} Chunks · ${next.errors.length?I18n.html`${next.errors.length} Lesehinweis(e)`:I18n.t('eingelesen')}`;
    $('.demo-dot').textContent=sourceKind==='demo'?I18n.t('Geladene Demowelt'):I18n.t('Lokal geladener Spielstand');
    $('.page-footer').firstChild.textContent=I18n.t('Inoffizielles Community-Projekt · Keine Verbindung zu Tellurion Mobile · ZIP nur lokal im Browser gelesen · ');
    cleanup();dialog.close();render();toast(I18n.t('Alle Ansichten verwenden jetzt die ausgewählte Welt.'));
   }catch(error){status(error.message||I18n.t('Daten konnten nicht übernommen werden.'));cleanup();}
  }
 };
 worker.postMessage({action:'inspect',file});
}
$('#confirm-import').onclick=()=>{const choice=$('input[name="import-world"]:checked');if(!choice||!worker)return;$('#confirm-import').hidden=true;$('#import-worlds').replaceChildren();$('#import-progress').hidden=false;status(I18n.t('Welt wird eingelesen …'));worker.postMessage({action:'load',prefix:choice.value});};
$('#open-zip').onclick=()=>$('#zip-file').click();$('#zip-file').onchange=()=>{const file=$('#zip-file').files[0];if(file){begin();inspect(file,'local');}};
$('#load-demo').onclick=async()=>{
 begin();abort=new AbortController();const signal=abort.signal;status(I18n.t('Demo-ZIP wird geladen …'));
 try{
  const response=await fetch('demo-source.json',{cache:'no-store',signal});if(!response.ok)throw Error(I18n.t('Demo-Konfiguration nicht erreichbar. Alternativ die Demo-ZIP herunterladen und lokal öffnen.'));
  const config=await response.json();const result=await fetch('demo.zip',{cache:'no-store',signal});if(!result.ok)throw Error(I18n.t('Demo-ZIP nicht erreichbar. Bitte später erneut versuchen.'));
  const reader=result.body.getReader();const parts=[];let size=0;
  while(true){const {value,done}=await reader.read();if(done)break;size+=value.length;if(size>128*1024*1024){await reader.cancel();throw Error(I18n.t('Demo-ZIP überschreitet die Downloadgrenze.'));}parts.push(value);}
  const blob=new Blob(parts),bytes=await blob.arrayBuffer(),digest=Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',bytes)),n=>n.toString(16).padStart(2,'0')).join('');
  if(digest!==config.sha256)throw Error(I18n.t('Die Demo-Prüfsumme stimmt nicht. Bitte neu laden; nichts wurde übernommen.'));
  if(!dialog.open||signal.aborted)return;inspect(new File([bytes],config.asset,{type:'application/zip'}),'demo');
 }catch(error){if(error.name!=='AbortError')status(error.message);}
};
resetDialog.addEventListener('close',()=>{if(resetDialog.returnValue==='reset'){$('#load-demo').click();}});
$('#source-name').textContent='RealmCraft Companion Demo';$('#source-detail').textContent=I18n.t('Demo-ZIP wird geladen …');$('.demo-dot').textContent='RealmCraft Companion Demo';
$('#load-demo').click();
})();

window.addEventListener('companion-language',()=>{
 $('#load-demo').textContent=I18n.t('Demo-ZIP laden');$('#open-zip').textContent=I18n.t('Eigene ZIP öffnen …');
 document.querySelector('.source-bar .eyebrow').textContent=I18n.t('DATENQUELLE');document.querySelector('.source-bar').setAttribute('aria-label',I18n.t('Datenquelle'));
 $('#source-name').textContent=state.source?state.source.name:awaitingDemo?'RealmCraft Companion Demo':I18n.t('Synthetische Beispieldaten');
 $('#source-detail').textContent=state.source?I18n.t(state.source.kind==='demo'?'Bereitgestellte Demo':'Lokale ZIP'):I18n.t(awaitingDemo?demoLoadMessage:'Keine ZIP geladen');
 document.querySelector('.demo-dot').textContent=I18n.t(state.source?state.source.kind==='demo'?'Geladene Demowelt':'Lokal geladener Spielstand':awaitingDemo?'RealmCraft Companion Demo':'Synthetische Demowelt');
 $('#mobile-reset').textContent=I18n.t('Demo zurücksetzen');
 document.querySelector('.page-footer').firstChild.textContent=I18n.t('Inoffizielles Community-Projekt · Keine Verbindung zu Tellurion Mobile · ')+(state.source?I18n.t('ZIP nur lokal im Browser gelesen'):I18n.t('Synthetische Beispieldaten'))+' · ';
});
