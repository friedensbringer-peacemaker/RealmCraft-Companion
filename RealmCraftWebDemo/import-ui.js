'use strict';
(function(){
const strip=document.createElement('section');strip.className='source-bar';strip.setAttribute('aria-label','Datenquelle');
strip.innerHTML='<div><span class="eyebrow">DATENQUELLE</span><strong id="source-name">Synthetische Beispieldaten</strong><span id="source-detail" class="small">Keine ZIP geladen</span></div><div class="toolbar"><button id="load-demo" class="primary">Demo-ZIP laden</button><button id="open-zip">Eigene ZIP öffnen …</button><input id="zip-file" type="file" accept=".zip,application/zip" hidden></div>';
$('.topbar').after(strip);
const dialog=document.createElement('dialog');dialog.id='import-dialog';dialog.innerHTML='<h2>Spielstand-ZIP öffnen</h2><p class="small">Die Datei wird nur in diesem Browser gelesen. Sie wird nicht hochgeladen oder verändert.</p><p id="import-status" role="status" aria-live="polite"></p><progress id="import-progress" max="100" value="0" hidden></progress><div id="import-worlds"></div><p class="small">Ein erfolgreicher Import ersetzt die aktuelle Ansicht und ihre Sitzungsänderungen. Bei einem Fehler bleibt der bisherige Datenstand erhalten.</p><div class="toolbar"><button id="cancel-import">Abbrechen</button><button id="confirm-import" class="primary" hidden>Ausgewählte Welt öffnen</button></div>';document.body.append(dialog);
let worker=null,sourceName='',sourceKind='local',abort=null;
const status=message=>$('#import-status').textContent=message;
function cleanup(){worker?.terminate();worker=null;abort?.abort();abort=null;$('#zip-file').value='';}
dialog.addEventListener('cancel',cleanup);$('#cancel-import').onclick=()=>{cleanup();dialog.close();};
function begin(){cleanup();$('#import-worlds').replaceChildren();$('#confirm-import').hidden=true;$('#import-progress').hidden=true;status('ZIP wird geprüft …');if(!dialog.open)dialog.showModal();}
function inspect(file,kind){
 sourceName=file.name;sourceKind=kind;
 worker=new Worker('import-worker.js');const activeWorker=worker;
 worker.onerror=()=>{if(worker!==activeWorker)return;cleanup();status('Der Import konnte nicht gestartet werden. Bitte Seite neu laden und einen aktuellen Browser verwenden.');};
 worker.onmessage=async({data})=>{
  if(worker!==activeWorker)return;
  if(data.type==='worlds'){
   status(`${data.worlds.length} Welt(en) gefunden. Bitte auswählen.`);const list=$('#import-worlds');
   data.worlds.forEach((w,i)=>{const label=document.createElement('label');label.className='world-choice';const input=document.createElement('input');input.type='radio';input.name='import-world';input.value=w.prefix;input.checked=i===0;const text=document.createElement('span');text.textContent=`${w.name} · ${w.chunks} Chunks · ID ${w.worldID}`;label.append(input,text);list.append(label);});$('#confirm-import').hidden=false;
  }else if(data.type==='progress'){$('#import-progress').value=data.done/data.total*100;status(`Karte und Kisten lesen: ${data.done} / ${data.total} Chunks`);}
  else if(data.type==='error'){status(data.message);$('#confirm-import').hidden=true;$('#import-progress').hidden=true;cleanup();}
  else if(data.type==='loaded'){
   try{
    status('Katalog und Ansichten vorbereiten …');const catalog=await getData('WorldCatalog');if(!dialog.open||worker!==activeWorker)return;
    const next=C.fromImport(data.result,catalog,{kind:sourceKind,filename:sourceName});
    state=next;undo=[];selectedSlot=0;transfer=null;mapFocus=null;window.ImportedMap?.reset();
    $('#source-name').textContent=next.source.name;$('#source-detail').textContent=`${sourceKind==='demo'?'Bereitgestellte Demo':'Lokale ZIP'} · ${Object.values(next.worldMap.dimensions).reduce((n,d)=>n+d.chunks.length,0)} Chunks · ${next.errors.length?`${next.errors.length} Lesehinweis(e)`:'eingelesen'}`;
    $('.demo-dot').textContent=sourceKind==='demo'?'Geladene Demowelt':'Lokal geladener Spielstand';
    $('.page-footer').firstChild.textContent='Inoffizielles Community-Projekt · Keine Verbindung zu Tellurion Mobile · ZIP nur lokal im Browser gelesen · ';
    cleanup();dialog.close();render();toast('Alle Ansichten verwenden jetzt die ausgewählte Welt.');
   }catch(error){status(error.message||'Daten konnten nicht übernommen werden.');cleanup();}
  }
 };
 worker.postMessage({action:'inspect',file});
}
$('#confirm-import').onclick=()=>{const choice=$('input[name="import-world"]:checked');if(!choice||!worker)return;$('#confirm-import').hidden=true;$('#import-worlds').replaceChildren();$('#import-progress').hidden=false;status('Welt wird eingelesen …');worker.postMessage({action:'load',prefix:choice.value});};
$('#open-zip').onclick=()=>$('#zip-file').click();$('#zip-file').onchange=()=>{const file=$('#zip-file').files[0];if(file){begin();inspect(file,'local');}};
$('#load-demo').onclick=async()=>{
 begin();abort=new AbortController();const signal=abort.signal;status('Demo-ZIP wird geladen …');
 try{
  const response=await fetch('demo-source.json',{cache:'no-store',signal});if(!response.ok)throw Error('Demo-Konfiguration nicht erreichbar. Alternativ die Demo-ZIP herunterladen und lokal öffnen.');
  const config=await response.json();const result=await fetch('demo.zip',{cache:'no-store',signal});if(!result.ok)throw Error('Demo-ZIP nicht erreichbar. Bitte später erneut versuchen.');
  const reader=result.body.getReader();const parts=[];let size=0;
  while(true){const {value,done}=await reader.read();if(done)break;size+=value.length;if(size>128*1024*1024){await reader.cancel();throw Error('Demo-ZIP überschreitet die Downloadgrenze.');}parts.push(value);}
  const blob=new Blob(parts),bytes=await blob.arrayBuffer(),digest=Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',bytes)),n=>n.toString(16).padStart(2,'0')).join('');
  if(digest!==config.sha256)throw Error('Die Demo-Prüfsumme stimmt nicht. Bitte neu laden; nichts wurde übernommen.');
  if(!dialog.open||signal.aborted)return;inspect(new File([bytes],config.asset,{type:'application/zip'}),'demo');
 }catch(error){if(error.name!=='AbortError')status(error.message);}
};
resetDialog.addEventListener('close',()=>{if(resetDialog.returnValue==='reset'){$('#source-name').textContent='Synthetische Beispieldaten';$('#source-detail').textContent='Keine ZIP geladen';$('.demo-dot').textContent='Synthetische Demowelt';window.ImportedMap?.reset();$('.page-footer').firstChild.textContent='Inoffizielles Community-Projekt · Keine Verbindung zu Tellurion Mobile · Synthetische Beispieldaten · ';}});
})();
