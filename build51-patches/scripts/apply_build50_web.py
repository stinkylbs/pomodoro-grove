from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[1]
app=ROOT/'public/app.js'
html=ROOT/'public/index.html'
js=app.read_text()

mushroom_re=r"function mushroomSpec\(p\)\{.*?return\{shape,color,face,count,spots\};\n\}"
mushroom_new="""function mushroomSpec(p){
 const r=random((Number.isFinite(p.seed)?p.seed:43)+9137),shape=mushroomShapes.includes(p.species)?p.species:mushroomShapes[Math.floor(r()*mushroomShapes.length)];
 const color=mushroomPalette[Math.floor(r()*mushroomPalette.length)],face=mushroomFaces[Math.floor(r()*mushroomFaces.length)];
 const roll=r();
 const count=roll<.01?0:roll<.14?1:roll<.31?2:roll<.53?3:roll<.75?4:roll<.90?5:6;
 const mask=mushroomMasks.get(shape),bb=mushroomCapBoxes.get(shape),spots=[];
 if(!mask||!bb)return{shape,color,face,count:0,spots:[]};
 const inside=(x,y)=>x>=0&&x<260&&y>=0&&y<260&&mask[(Math.floor(y)*260+Math.floor(x))*4+3]>110,base=Math.min(bb[2],bb[3]);
 const sizeBands={1:[.17,.25],2:[.145,.22],3:[.118,.182],4:[.106,.17],5:[.108,.168],6:[.102,.162]},band=sizeBands[count]||[.118,.182],targets=[];
 for(let i=0;i<count;i++){
  let radius=base*(band[0]+r()*(band[1]-band[0]));
  if(count===1)radius*=r()<.75?(1.18+r()*.50):(1+r()*.18);
  else if(count===2)radius*=r()<.55?(1.12+r()*.42):(1+r()*.16);
  else if(count>=5)radius*=r()<.32?(1.08+r()*.14):(1+r()*.08);
  else if(count>=3&&r()<.20)radius*=1.08+r()*.18;
  targets.push(radius);
 }
 targets.sort((a,b)=>b-a);
 for(const target of targets){
  let chosen=null;
  for(let attempt=0;attempt<3600;attempt++){
   const radius=target*(attempt<1350?1:attempt<2350?.94:attempt<3100?.87:.81),x=bb[0]+r()*bb[2],y=bb[1]+r()*bb[3];
   if(!inside(x,y))continue;
   const gap=count<=2?12:count===3?9:count===4?7:5.5;
   if(spots.some(s=>Math.hypot(s.x-x,s.y-y)<s.r+radius+gap))continue;
   chosen={x,y,r:radius,rot:(r()-.5)*.7,jitter:Math.floor(r()*1e8)};
   break;
  }
  if(chosen)spots.push(chosen);
 }
 return{shape,color,face,count,spots};
}"""
js,n=re.subn(mushroom_re,mushroom_new,js,count=1,flags=re.S)
assert n==1, f'mushroomSpec patch failed ({n})'

js=js.replace("philosophy: {label:'Philosophy',plant:'Elder trees',color:'#69BBA2',species:['Moss elder','Hollow guardian','Ivory elder']},",
              "philosophy: {label:'Philosophy',plant:'Elder Trees',color:'#69BBA2',species:['Moss elder','Hollow guardian','Ivory elder']},")
assert "plant:'Elder Trees'" in js

draw_re=r"function drawCategoryIcons\(\)\{[^\n]*\}"
draw_new="""function drawCategoryIcons(){
 const previewSize={news:[72,68],reading:[80,74],philosophy:[86,82],vocabulary:[82,72],studying:[46,43]},targetBottom=198;
 document.querySelectorAll('[data-category]').forEach(button=>{
  const category=button.dataset.category,canvas=button.querySelector('canvas'),size=previewSize[category]||[80,74],boxW=size[0],boxH=size[1],scratch=document.createElement('canvas');
  scratch.width=220;scratch.height=210;
  const sc=scratch.getContext('2d');sc.setTransform(2,0,0,2,0,0);sc.clearRect(0,0,110,105);
  drawPlantInBox(sc,{category,species:chosenSpecies(category)},(110-boxW)/2,104-boxH,boxW,boxH);
  const bounds=canvasAlphaBounds(scratch),dy=bounds?targetBottom-bounds.bottom:0;
  canvas.width=220;canvas.height=210;
  const c=canvas.getContext('2d');c.clearRect(0,0,220,210);c.drawImage(scratch,0,dy);
 });
}"""
js,n=re.subn(draw_re,draw_new,js,count=1)
assert n==1, f'drawCategoryIcons patch failed ({n})'
assert 'function renderShop(){' in js, 'renderShop missing after patch'
app.write_text(js)

ht=html.read_text().replace('Elder trees','Elder Trees')
css='''\n<style id="build50-safe-layout">\n.categories{grid-template-columns:repeat(5,minmax(0,1fr))!important;gap:6px!important;max-width:430px!important;margin:0 auto 10px!important;align-items:end!important}\n.category,.category:hover{min-width:0!important;padding:8px 3px 10px!important}\n.category canvas{display:block!important;width:100%!important;max-width:74px!important;height:auto!important;aspect-ratio:100/95!important;margin:0 auto!important}\n.category strong{font-size:10px!important;min-height:29px!important;padding:4px 0 6px!important;display:flex!important;align-items:center!important;justify-content:center!important}\n.category span{font-size:9px!important;margin-top:5px!important}\n@media(max-width:480px){\n .categories{grid-template-columns:repeat(5,minmax(0,1fr))!important;gap:5px!important;max-width:100%!important}\n .category,.category:hover{padding:7px 2px 9px!important;border-radius:18px 17px 19px 17px!important}\n .category canvas{max-width:55px!important}\n .category strong{font-size:9.5px!important;min-height:27px!important;padding:3px 0 5px!important}\n .category span{font-size:8.5px!important;margin-top:4px!important}\n}\n</style>\n'''
if 'id="build50-safe-layout"' not in ht:
    assert '</head>' in ht
    ht=ht.replace('</head>',css+'</head>',1)
html.write_text(ht)
print('Build 50 web changes applied safely.')
