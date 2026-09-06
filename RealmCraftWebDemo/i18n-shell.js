'use strict';
(function(){
const texts=[],attributes=[];
for(const selector of ['.sidebar','.topbar','#reset-dialog','.skip','.page-footer','noscript']){
 const element=document.querySelector(selector);if(!element)continue;
 const walker=document.createTreeWalker(element,NodeFilter.SHOW_TEXT);let node;
 while((node=walker.nextNode()))if(node.textContent.trim())texts.push([node,node.textContent]);
 for(const e of [element,...element.querySelectorAll('*')])for(const attr of ['aria-label','title','placeholder'])if(e.hasAttribute(attr))attributes.push([e,attr,e.getAttribute(attr)]);
}
function update(){document.documentElement.lang=I18n.language;for(const [node,original] of texts)node.textContent=I18n.t(original);for(const [node,attr,original] of attributes)node.setAttribute(attr,I18n.t(original));}
const label=document.createElement('label');label.className='language-picker';label.innerHTML='<span>Language / Sprache</span><select id="language" aria-label="Language / Sprache"><option value="en">English</option><option value="de">Deutsch</option></select>';document.querySelector('.topbar').append(label);
const select=label.querySelector('select');select.value=I18n.language;select.onchange=()=>{I18n.setLanguage(select.value);update();window.dispatchEvent(new Event('companion-language'));if(typeof render==='function')render();};update();
})();
