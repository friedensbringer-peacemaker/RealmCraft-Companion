/* A compact strip keeps common toggles visible; secondary layers open on demand. */
(() => {
 const en=document.documentElement.lang==='en';
 window.AtlasQuickControls={install(onMarkers,onLabels,onSearchFocus){
  const $=id=>document.getElementById(id),bar=$('quick-controls');if(!bar)return;
  const make=(tag,text,cls)=>{const e=document.createElement(tag);if(text)e.textContent=text;if(cls)e.className=cls;return e;};
  const row=make('div','','quick-row');
  const search=$('sign-search');
  if(search){const form=make('form','','map-search');form.setAttribute('role','search');form.setAttribute('aria-label',en?'Search signs on this map':'Schilder auf dieser Karte suchen');
   search.placeholder=en?'Search signs…':'Schilder suchen …';search.title=en?'Search sign text or coordinates. Enter: next result.':'Schildtext oder Koordinaten suchen. Enter: nächster Treffer.';
   form.append(search,$('sign-count'),$('sign-prev'),$('sign-next'));form.onsubmit=e=>{e.preventDefault();$('sign-next').click();};row.append(form);
  }
  const visible=$('poi-visible').closest('label');$('poi-show').textContent=en?'Tag markers':'Tag-Markierungen';row.append(visible);
  const own=make('label','','check'),input=make('input');input.type='checkbox';input.checked=true;input.id='own-places-visible';input.onchange=()=>onMarkers(input.checked);own.append(input,make('span',en?'My places':'Eigene Orte'));row.append(own);
  const menu=make('details','','layer-menu'),summary=make('summary',en?'Layers & options':'Ebenen & Optionen');menu.append(summary);
  const panel=make('div','','layer-options');panel.append(make('label',en?'Tag category':'Tag-Kategorie'));panel.append($('poi-kind'));
  const labels=make('label','','check'),names=make('input');names.type='checkbox';names.id='poi-labels-visible';names.onchange=()=>onLabels?.(names.checked);labels.append(names,make('span',en?'All tag labels':'Alle Tag-Namen'));panel.append(labels);
  if($('sign-visible'))panel.append($('sign-visible').closest('label'));panel.append($('grid').closest('label'));
  const transport=$('transport-layers');if(transport){panel.append(transport);const info=make('details','','layer-help');info.append(make('summary',en?'About transport layers':'Hinweise zu Transportnetzen'));for(const p of [...transport.querySelectorAll('p')])info.append(p);transport.append(info);}
  panel.append($('ownership-toggle'));
  if($('marker-legend'))panel.append($('marker-legend'));
  menu.append(panel);row.append(menu);bar.append(row);if(search){const focus=make('label','','check search-focus');focus.id='search-focus-control';focus.hidden=true;const check=make('input');check.type='checkbox';check.checked=true;check.id='search-focus';check.onchange=()=>onSearchFocus?.(check.checked);focus.append(check,make('span',en?'Only search results · other layers hidden':'Nur Suchtreffer · andere Ebenen ausgeblendet'));bar.append(focus);}if(search){const status=make('p','','search-status');status.id='sign-search-status';status.setAttribute('role','status');status.hidden=!search.disabled;status.textContent=search.disabled?$('sign-note').textContent:'';bar.append(status);}bar.setAttribute('aria-label',en?'Map layer controls':'Karteneinblendungen');
  document.addEventListener('pointerdown',e=>{if(!menu.contains(e.target))menu.open=false;});menu.addEventListener('keydown',e=>{if(e.key==='Escape'){menu.open=false;summary.focus();e.stopPropagation();}});
  const note=$('poi-note');if(note){const help=make('details','','layer-help');help.append(make('summary',en?'About automatic detection':'Hinweise zur Erkennung'));note.parentNode.insertBefore(help,note);help.append(note);}
 }};
})();
