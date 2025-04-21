import { chunk0 } from './omnidef_chunk0.js';


import { chunk1 } from './omnidef_chunk1.js';


import { chunk2 } from './omnidef_chunk2.js';


import { chunk3 } from './omnidef_chunk3.js';








                let def = '';


                def += chunk0;


def += chunk1;


def += chunk2;


def += chunk3;








                def = decodeURIComponent(atob(def));    


//export const OMNIDEF = JSON.parse(def);


let tmpDef =  JSON.parse(def);


tmpDef.sOmniScriptId ='a2s8Y000008HqdgQAC';


export const OMNIDEF =tmpDef;