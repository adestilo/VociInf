xquery version "3.1";

(:~ This is the default application library module of the progettotesi app.
 :
 : @authors Diletta Lelli, Adele Stilo
 : @version 1.0.0
 : @see http://exist-db.org
 :)

(: Module for app-specific template functions :)
module namespace app="http://exist-db.org/apps/proget/templates";
import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace lib="http://exist-db.org/xquery/html-templating/lib";
import module namespace config="http://exist-db.org/apps/proget/config" at "config.xqm";
(: modulo kwic :)
import module namespace kwic= "http://exist-db.org/xquery/kwic";



declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei = 'http://www.tei-c.org/ns/1.0';
declare namespace myapp="http://example.com/app";
declare namespace functx = "http://www.functx.com";


declare option output:method "html";
declare option output:media-type "text/html";
declare option output:indent "yes";




declare function app:footer($node as node(), $model as map (*))
{
    <img src="resources/images/unipi-logo-orizz.png" id="unipilogo" alt="existdb"/>
};




(: formatta ricorsivamente i figli e sotto-figli di un enunciato espanso con exist:match ottenuto da ricerche con lucene :) 
declare
function app:formatta-match($nodo_corrente as node()) {
    let $localName := $nodo_corrente/local-name()
    return 
        (: se localName del nodo corrente è stringa vuota, è un nodo di testo semplice (non si evidenzia) :)
        if ($localName = "" ) then
            <span class="testo_default"> { data($nodo_corrente) } </span>
        else
            (: se localName del nodo corrente è "match", è un nodo da evidenziare :)
            if ($localName = "match" ) then
                <span class="evidenziato"> { data($nodo_corrente) } </span>
            else
                (: altrimenti (cioè per tutti gli altri tipi di nodo) si effettua la ricorsione sui figli del nodo corrente:)
                <span>
                    {
                        for $nodo_figlio in $nodo_corrente/node()
                        return app:formatta-match($nodo_figlio)
                    }
                </span>
};

(: creo una funzione per prendere tutti gli 'u' :)

declare function app:intervista($node as node(), $model as map(*)) {
  let $testimonianza := request:get-parameter("testimonianza", "")
  let $xmls := collection("/db/apps/proget/xml")/*
  let $testimonianza_ := replace($testimonianza, "\s+", "_")

  let $fileXML := (
    for $xml in $xmls
    let $testimone := $xml//tei:person[@role = 'testimone']
    let $forename := $testimone/tei:persName/tei:forename
    let $surname := $testimone/tei:persName/tei:surname
    where $forename = tokenize($testimonianza, '\s+')[1] and $surname = tokenize($testimonianza, '\s+')[2]
    return $xml
  )
  
  let $xslt := doc("/db/apps/proget/xslt/xslt.xsl")
  let $newHTML := transform:transform($fileXML, $xslt, ())
  
  return $newHTML
  
  
};

declare function app:testimonianza($node as node(), $model as map(*)) {
  let $testimonianza := request:get-parameter("testimonianza", "")
  let $xmls := collection("/db/apps/proget/xmlscritte")/*
  let $testimonianza_ := replace($testimonianza, "\s+", "_")

  let $fileXML := (
    for $xml in $xmls
    let $testimone := $xml//tei:person[@role = 'testimone']
    let $forename := $testimone/tei:persName/tei:forename
    let $surname := $testimone/tei:persName/tei:surname
    where $forename = tokenize($testimonianza, '\s+')[1] and $surname = tokenize($testimonianza, '\s+')[2]
    return $xml
  )
  
  let $xslt := doc("/db/apps/proget/xslt/xsltscritte.xsl")
  let $newHTML := transform:transform($fileXML, $xslt, ())
  
  return $newHTML
  
  
};





(: creo una funzione per recuperare il nome e il cognome di una persona a partire dal suo @xml:id dentro persName :)

declare function app:nome_persona_da_id($id_persona) {
    let $dati_persone := doc("/db/apps/proget/xml/Fiano_Codifica.xml")//tei:persName
    for $persona in $dati_persone 
    where $persona/@xml:id = $id_persona
    return data($persona) (: con data() si ottiene il contenuto testuale dell'elemento person, sia che sia nome / cognome o una descrizione:)
    };

(: questa funzione serve per evidenziare il fenomeno che mi interessa nell'enunciato :)    
    
declare function app:formatta_u_con_elementi($nodo_corrente as node(), $tipo as xs:string, $classe as xs:string) {
    let $localName := $nodo_corrente/local-name()
    return 
        (: se localName del nodo corrente è stringa vuota, è un nodo di testo semplice (non si evidenzia) :)
        if ($localName = "") then
            <span class="testo_default"> { data($nodo_corrente) } </span>
        else
            (: se localName del nodo corrente è del tipo da evidenziare, si evidenzia (via classe stile css) :)
            if ($localName = $tipo ) then
                <span class="{ $classe }"> { data($nodo_corrente) } </span>
            else
                (: altrimenti (cioè per tutti gli altri tipi di nodo) si effettua la ricorsione sui figli del nodo corrente:)
                <span>
                    {
                        for $nodo_figlio in $nodo_corrente/node()
                        return app:formatta_u_con_elementi($nodo_figlio, $tipo, $classe)
                    }
                </span>
};

(: lavoro con il regesto in maniera dinamica e automatica :)

(: creo una funzione dinamica e automatica che mi conta quante parti del regesto ci sono :)

declare function app:contaRegesti($node as node(), $model as map(*)) {
  let $testimonianza := request:get-parameter("testimonianza", "") (: es. Nedo Fiano :)
  let $testimonianza_ := replace($testimonianza, "\s+", "_") (: es. Nedo_Fiano :)
  let $xmlCollection := collection("/db/apps/proget/xml")
  let $count := count(
    for $xml in $xmlCollection/*
    let $testimone := $xml//tei:person[@role = 'testimone']
    let $forename := $testimone/tei:persName/tei:forename
    let $surname := $testimone/tei:persName/tei:surname
    where $forename = tokenize($testimonianza, '\s+')[1] and $surname = tokenize($testimonianza, '\s+')[2] (: dove $forename = $testimonianza[1] e $surname = $testimonianza[2]. Esempio: $forename = Nedo and $surname = Fiano :)
    let $timeline := $xml//tei:timeline[@xml:id = 'TL1']
    return $timeline//tei:when
  )
  return $count
};

(: creo una funzione dinamica che per ogni "item" dentro "list", mi crea un div :)

declare function app:restituisciRegesti($node as node(), $model as map(*)) {
  let $testimonianza := request:get-parameter("testimonianza", "") (: es. Nedo Fiano :)
  let $xmls := collection("/db/apps/proget/xml")/* (: Ottenere tutti i documenti XML nella cartella XML :)
  let $testimonianza_ := replace($testimonianza, "\s+", "_") (: es. Nedo_Fiano :)
  
  let $fileXML := (
    for $xml in $xmls
    let $testimone := $xml//tei:person[@role = 'testimone']
    let $forename := $testimone/tei:persName/tei:forename
    let $surname := $testimone/tei:persName/tei:surname
    where $forename = tokenize($testimonianza, '\s+')[1] and $surname = tokenize($testimonianza, '\s+')[2] (: dove $forename = $testimonianza[1] e $surname = $testimonianza[2]. Esempio: $forename = Nedo and $surname = Fiano :)
    return $xml
  )
  
  let $list := $fileXML//tei:abstract/tei:ab/tei:list
  let $timeline := $fileXML//tei:timeline[@xml:id="TL1"]

  for $i in 1 to count($list//tei:item)
    let $audio_id := "my-audio-" || $i
    let $item := $list//tei:item[$i]
    let $synch := $item/@synch/string()
    let $xml_id := tokenize($synch, '#')[2]
    let $inizio := $timeline//tei:when[@xml:id = $xml_id]/@absolute/string()
    let $fine := if ($i < count($list//tei:item)) then
      let $synch := $list//tei:item[$i + 1]/@synch/string()
      let $xml_id := tokenize($synch, "#")[2]
      let $prossimo_inizio := $timeline//tei:when[@xml:id = $xml_id]/@absolute/string()
      return $prossimo_inizio
    else ()
    let $div := element div {
      attribute class {"regesto-" || $i},
      attribute synch {$synch},
      $item,
      element span {
        attribute class {"minuto"},
        concat("Questa parte inizia al minuto: ", $inizio, if ($fine) then concat(" e finisce al minuto: ", $fine) else (" e continua fino alla fine dell'audio."))
      },
      element audio {
        attribute id {$audio_id}, 
        attribute controls {"controls"},
        attribute data-inizio {$inizio},
        attribute data-fine {$fine},
        element source {
          attribute src {concat("http://127.0.0.1/Audio/", $testimonianza_, ".mp3")}, 
          attribute type {"audio/mpeg"}
        }
      }
    }
    return $div
};



(: creo la funzione per il catalogo. Dentro la collection "xml" ci sono i file .xml. Per ogni file, creo un div :)

declare function app:creaCatalogo($node as node(), $model as map(*)) {
  for $xml in collection("/db/apps/proget/xml")/*
  let $testimone := $xml//tei:person[@role = 'testimone']
  let $nome-format0 := concat($testimone/tei:persName/tei:forename, '_', $testimone/tei:persName/tei:surname) (: es. Nedo_Fiano :)
  let $nome-format := replace($nome-format0, '_', ' ') (: es. Nedo Fiano :)
  return
    <div class="catSing" onclick='riportaAllaTestimonianza("{$nome-format}")'>
        <h3>{concat("Testimonianza di ", $nome-format)}</h3>
        <img src="resources/images/noimage.jpeg" id="imgcat" alt="" data-testimone="{$nome-format0}"/> 
    </div>
};

declare function app:creaCatalogoScritte($node as node(), $model as map(*)) {
  for $xml in collection("/db/apps/proget/xmlscritte")/*
  let $testimone := $xml//tei:person[@role = 'testimone']
  let $nome-format0 := concat($testimone/tei:persName/tei:forename, '_', $testimone/tei:persName/tei:surname) (: es. Nedo_Fiano :)
  let $nome-format := replace($nome-format0, '_', ' ') (: es. Nedo Fiano :)
  return
    <div class="catSing" onclick='riportaAllaTestimonianza("{$nome-format}")'>
        <h3>{concat("Testimonianza di ", $nome-format)}</h3>
        <img src="resources/images/noimage.jpeg" id="imgcat" alt="" data-testimone="{$nome-format0}"/> 
    </div>
};

declare function app:creaCatalogoMini($node as node(), $model as map(*)) {
  for $xml in collection("/db/apps/proget/xml")/*
  let $testimone := $xml//tei:person[@role = 'testimone']
  let $nome-format0 := concat($testimone/tei:persName/tei:forename, '_', $testimone/tei:persName/tei:surname) (: es. Nedo_Fiano :)
  let $nome-format := replace($nome-format0, '_', ' ') (: es. Nedo Fiano :)
  return
    <div class="catSingMini">
        <h3>{concat("Testimonianza di ", $nome-format)}</h3>
    </div>
};

declare function app:creaCatalogoMiniScritte($node as node(), $model as map(*)) {
  for $xml in collection("/db/apps/proget/xmlscritte")/*
  let $testimone := $xml//tei:person[@role = 'testimone']
  let $nome-format0 := concat($testimone/tei:persName/tei:forename, '_', $testimone/tei:persName/tei:surname) (: es. Nedo_Fiano :)
  let $nome-format := replace($nome-format0, '_', ' ') (: es. Nedo Fiano :)
  return
    <div class="catSingMiniScritte">
        <h3>{concat("Testimonianza di ", $nome-format)}</h3>
    </div>
};


declare function app:creaTitoloCatalogo($node as node(), $model as map(*)) {
  let $testimonianza := request:get-parameter("testimonianza", "")
  let $nomeFile := replace($testimonianza, "\s+", "_")
  return
      <div id="divInd">
        <h1>Testimonianza di { $testimonianza }</h1>
        <img src="resources/images/noimage.jpeg" id="imgInd" alt="{concat("Immagine di ", $testimonianza)}" data-testimone="{$nomeFile}" />
       
    </div>
};

declare function app:creaTitoloCatalogoScritte($node as node(), $model as map(*)) {
  let $testimonianza := request:get-parameter("testimonianza", "")
  let $nomeFile := replace($testimonianza, "\s+", "")
  return
        <div id="divInd">
        <h1>Testimonianza di { $testimonianza }</h1>
        <img src="resources/images/noimage.jpeg" id="imgInd" alt="{concat("Immagine di ", $testimonianza)}" data-testimone="{$nomeFile}" />
       
    </div>
};


(: creo una funzione che crea un audio HTML con la source di chi sta parlando :)

declare function app:creaAudio($node as node(), $model as map(*)) {
    let $testimonianza := request:get-parameter("testimonianza", "") (: es. Nedo_Fiano :)
    let $testimonianza_ := replace($testimonianza, "\s+", "_") (: es. Nedo_Fiano :)
    return 
        <audio id="audio-intervista" controls="controls">
                <source src="{concat("http://127.0.0.1/Audio/", $testimonianza_, ".mp3")}"/>
            </audio>
};


declare function local:generaTemplate($xml as node(), $parola as xs:string) as element(template) {
  <template>
  {
    for $u in $xml//u[contains(text(), $parola)]
    return
    <enunciato>{$u}</enunciato>
  }
  </template>
};



(: form interattiva con query : ricerca persone (testo nome cognome e descrizioni) :)
declare
%templates:wrap
function app:query_form_persone($node as node(), $model as map(*), $query as xs:string?, $fuzzy as xs:string?) {
    (: controllo se c'è una query (è un parametro opzionale che arriva nel caso dalla richiesta get della form) :)
    let $no_query := not($query)
    return
        (: se non c'è una query non si genera nessun risultato (giusto un <br> per il layout :)
        if ($no_query) then
            <br />
        else
            (: altrimenti si genera la tabella dei risultati :)
            <table class="table table-striped table-borderless">
                <thead>
                    <tr><th colspan="4" scope="col">Risultati per "{ $query }":</th></tr>
                    <tr>
                        <th scope="col">Nome</th>
                        <th scope="col">Cognome</th>
                        <th scope="col">Ruolo</th>
                        <th scope="col"></th>
                    </tr>
                </thead>
                <tbody>
                    {
                        (: 
                        : si utilizza la funzione app:query_cerca che a sua volta utilizza il motore lucene per ottenere i risultati della ricerca
                        : gli elementi ottenuti sono di tipo tei:person: per ogni risultato si produce in output nome, cognome, ruolo e link informativo
                        :)
                        for $risultato in app:query_cerca($query, $fuzzy)
                        return 
                            <tr>
                                <td>{ data($risultato/tei:persName/tei:forename) }</td>
                                <td>{ data($risultato/tei:persName/tei:surname) }</td>
                                <td>{ data($risultato/tei:persName/tei:roleName) }</td>
                                <td><a href="{ data($risultato/tei:persName/@ref) }">Info</a></td>
                            </tr>
                    }
                </tbody>
            </table>
};

(: funzione di ricerca persone da query stringa
 : utilizza il motore lucene per effettuare le ricerche
 : opzionalmente è possibile eseguire una ricerca di tipo "fuzzy" (testo "simile" a quello cercato)
 :)
declare
function app:query_cerca( $query as xs:string, $fuzzy as xs:string?) {
    
    (: per rendere più comoda la ricerca all'utente ho scelto di utilizzare un wildcard nell'espressione della query:
    :  quando richiedo una ricerca "semplice" voglio poter far trovare risultati anche se la parola nella query è parziale (per esempio gat -> gatto)
    :  per fare questo si aggiunge un wildcard asterisco "*" alla fine della query
    :  se invece si richiede una ricerca fuzzy si concatena un wildcard tilde "~" (ricerca per parole simili)
    :)
    let $wildcard :=
        if ( not($fuzzy) ) then "*"
        else "~"

    (: seguendo la guida exist relativa all'utilizzo delle query lucene, per questioni di sicurezza, 
    : si effettua una rimozione degli eventuali caratteri speciali (ho preso questo codice direttamente in rete)
    :)
    let $query_filtrata := replace($query, "[&amp;&quot;-*;-`~!@#$%^*()_+-=\[\]\{\}\|';:/.,?(:]", "")
    
    (: con la query ripulita, si inserisce il wildcard :)
    let $query_con_wildcard := concat($query_filtrata, $wildcard)
    
    (: i dati su cui si effettua la ricerca, sono elementi di tipo person:
    :  si trovano, come listPerson, sia nel back che nel teiHeader
    :  vado a concatenare tutti gli elementi person di entrambe le listPerson, in un'unica sequenza
    :)
    let $dati_persone := (
            doc( $config:app-root || "/xml/Idek_Wolfowicz.xml" )/tei:TEI/tei:text/tei:back/tei:listPerson//tei:person,
            doc( $config:app-root || "/xml/Idek_Wolfowicz.xml" )/tei:TEI/tei:teiHeader/tei:profileDesc/tei:particDesc/tei:listPerson//tei:person
        )

    (: a questo punto, posso fare la ricerca (ho seguito le guide existdb per utilizzare lucene, ricerca fulltext) e restituire i risultati :)
    for $hit in $dati_persone[ft:query(., $query_con_wildcard)]
    return $hit
    
};


(: funzione di ricerca parole su enunciati di uno specifico parlante
 : utilizza il motore lucene per effettuare le ricerche
 : opzionalmente è possibile eseguire una ricerca di tipo "parziale" del testo (altrimenti si effettua una ricerca esatta)
 :)

(: formatta ricorsivamente i figli e sotto-figli di un enunciato espanso con exist:match ottenuto da ricerche con lucene :) 


(: funzione che serve per inserire una sottostringa in una posizione specifica (trovata online) :)
declare function functx:insert-string
  ( $originalString as xs:string? ,
    $stringToInsert as xs:string? ,
    $pos as xs:integer )  as xs:string {

   concat(substring($originalString,1,$pos - 1),
             $stringToInsert,
             substring($originalString,$pos))
 } ;
 (: funzione che serve per rendere maiuscolo il primo carattere della stringa (trovata online) :)
 declare function functx:capitalize-first
  ( $arg as xs:string? )  as xs:string? {

   concat(upper-case(substring($arg,1,1)),
             substring($arg,2))
 } ;
 

(: FUNZIONE CHE SMISTA LE VARIE RICERCHE :)
declare function app:ricerca($node as node(), $model as map(*), $searchTest as xs:string?, $smista as xs:string?, $term as xs:string*, $choose as xs:string*){
            let $testimonianzasist := replace($searchTest, "%20", "_")
            let $testimonianzasist := replace($testimonianzasist, " ", "_")
            return 
                switch($smista)
                case "wildcard" return app:wildcard($testimonianzasist, $term)
                case "fuzzy" return app:ricercafuzzy($testimonianzasist, $term)
                case "esatta" return app:ricercaesatta($testimonianzasist, $term)
                case "booleana" return app:cercabool($testimonianzasist, $term, $choose)
                default return ""
};

(: RICERCA BOOLEANA :)

(: funzione che calcola i risultati della ricerca booleana, tutti i testimoni :)
declare function app:risultatifinaliboolAll($file-path, $bool, $query){
    let $hits := doc($file-path)//tei:u[ft:query(., $query)]
    return
    <table>{(
            <tr><th>{concat('utterances trovate: ',count($hits))}</th></tr>,
            for $hit in $hits 
            order by ft:score($hit) descending
            let $id := $hit/@xml:id
        return
            for $h in $hit
            let $s := <span>{string($h)}</span>
            let $e := util:expand($h)
            let $xslt := doc("/db/apps/proget/xslt/xsltbool.xsl")
            let $newe := transform:transform($e, $xslt, ())
            return
            <tr>
                <td class="table">
                <span class="xmlid">{string($id)}</span><br/>
                <span>{$newe}</span>
                </td>
            </tr>)}</table>
};

(: funzione che calcola i risultati della booleana, singolo testimone :)
declare function app:risultatifinalibool($file-path, $bool, $query){
    <table>{ 
        for $hit in doc($file-path)//tei:u[ft:query(., $query)]
        order by ft:score($hit) descending
    let $id := $hit/@xml:id
    return
        for $h in $hit
        (:  :let $m := kwic:get-matches($h):)
        let $s := <span>{string($h)}</span>
        let $e := util:expand($h)
        let $xslt := doc("/db/apps/proget/xslt/xsltbool.xsl")
        let $newe := transform:transform($e, $xslt, ())
        return
        <tr>
            <td class="table">
            <span class="xmlid">{string($id)}</span><br/>
            <span>{$newe}</span>
            </td>
        </tr>}</table>
};


(: funzione che prepara ai risultati della ricerca booleana, tutti i testimoni :)  
declare function app:risboolAll($bool as xs:string*, $numbool as xs:integer?, $iter as xs:string?, $choose as xs:string*, $block as xs:string?, $numterm1 as xs:integer?, $numterm2 as xs:integer?){
    let $file-path := concat("/db/apps/proget/xml/",$iter,".xml")
    let $query := 
    <query>
        <bool>
            <bool occur="{$block}">
                <near ordered="yes" slop="3">{
                for $i in 1 to $numterm1
                return 
                    <term occur="{$choose[$i]}">{$bool[$i]}</term>
                }</near>
            </bool>
            <bool occur="{$block}">
                <near ordered="yes" slop="3">{
                     for $i in 1 to $numterm2
                return 
                    <term occur="{$choose[$i]}">{$bool[$i]}</term>
                }</near>
            </bool>
        </bool>
    </query>
    return  
        app:risultatifinaliboolAll($file-path, $bool, $query)
};


(: funzione che stampa i bottoni-collapse :)
declare function app:singleCardBool($node as node(), $model as map(*),$boolAll as xs:string*, $numboolAll as xs:integer?, $iterAll as xs:string?, $chooseAll as xs:string*, $blockAll as xs:string?, $numterm1All as xs:integer?, $numterm2All as xs:integer?){
    if ($blockAll = "must" or $blockAll = "should")
    then
    <div  class="accordion" id="accordionExample" >{
    for $xml in collection("/db/apps/proget/xml")/*
                let $testimone := $xml//tei:person[@role = 'testimone']
                let $nome-format0 := concat($testimone/tei:persName/tei:forename, '_', $testimone/tei:persName/tei:surname) (: es. Nedo_Fiano :)
                let $nome-format := replace($nome-format0, '_', ' ')
                return
        let $es := concat("bool[", $numboolAll, "]")
        return
            
            <div class="card">
                <div class="card-header" id="heading{$nome-format0}">
                    <h2 class="mb-0">
                        <!-- data-toggle, data-target, aria-expanded, 
                            aria-controls attributes are used -->
                        <!-- The toggling functionality are intact -->
                        <button class="btn btn-link collapsed"
                            type="button" data-toggle="collapse"
                            data-target="#collapse{$nome-format0}"
                            aria-expanded="false"
                            aria-controls="collapse{$nome-format0}">
                            {$nome-format0}
                        </button>
                    </h2>
                </div>
                
                <div id="collapse{$nome-format0}" class="collapse"
                    aria-labelledby="heading{$nome-format0}"
                    data-parent="#accordionExample">
                <div class="card-body">
                {app:risboolAll($boolAll, $numboolAll, $nome-format0, $chooseAll, $blockAll, $numterm1All, $numterm2All)} 
                </div>
                </div>
            </div>}</div>
        else ""
};

(: funzione che crea la form per relazione tra blocchi e quantita di termini, tutti i testimoni :)
declare function app:showformAll($bool as xs:string*, $numbool as xs:integer?, $iter as xs:string?, $choose as xs:string*){
    <div>
        <form id="showform2">
            <p><b>Parole cercate:</b> {$bool}</p><br/>
            <div>
            <p class="pBlockAll">{"Scegli la relazione tra i due blocchi"}</p>
            <select id="blockAll" name="blockAll" aria-label="Default select example">
            <option value=""/>
            <option value="should">Should</option>
            <option value="must">Must</option>
            </select>
            </div>
            <div>
            <p class="pTermAll">{"Scegli quanti termini inserire nel primo blocco"}</p>
            <select id="numterm1All" name="numterm1All" aria-label="Default select example">
            <option value=""/>
            {for $i in 1 to $numbool
            return 
                <option value="{$i}">{$i}</option>}
            </select>
            </div>
            <div>
            <p class="pTermAll">{"Scegli quanti termini inserire nel secondo blocco"}</p>
            <select id="numterm2All" name="numterm2All" aria-label="Default select example">
            <option value=""/>
            {for $i in 1 to $numbool
            return 
                <option value="{$i}">{$i}</option>}
            </select>
            </div>
            {for $i in 1 to ($numbool)
            return
                <input name="chooseAll" value="{$choose[$i]}" type="hidden"/>}
                 {for $i in 1 to ($numbool)
            return
                <input name="boolAll" value="{$bool[$i]}" type="hidden"/> }
            <input name="iterAll" value="{$iter}" type="hidden"/>
            <input name="numboolAll" value="{$numbool}" type="hidden"/>
            <button type="submit" class="btn btn-primary bricerca">Invia</button>
        </form>
        </div>
};

(: funzione che prepara il calcolo dei risultati, singolo testimone :)
declare function app:risbool($node as node(), $model as map(*),$bool as xs:string*, $numbool as xs:integer?, $iter as xs:string?, $choose as xs:string*, $block as xs:string?, $numterm1 as xs:integer?, $numterm2 as xs:integer?){
    let $file-path := concat("/db/apps/proget/xml/",$iter,".xml")
  
    let $query := 
    <query>
        <bool>
            <bool occur="{$block}">
                <near ordered="yes" slop="3">{
                for $i in 1 to $numterm1
                return 
                    <term occur="{$choose[$i]}">{$bool[$i]}</term>
                }</near>
            </bool>
            <bool occur="{$block}">
                <near ordered="yes" slop="3">{
                     for $i in 1 to $numterm2
                return 
                    <term occur="{$choose[$i]}">{$bool[$i]}</term>
                }</near>
            </bool>
        </bool>
    </query>
      let $conta := count(app:risultatifinalibool($file-path, $bool, $query)//tr)
    return
        if ($conta > 0)
        then
            
        <div class="cercabool" id="recap">
            <p><b>Tipo di ricerca:</b> Booleana </p>
            <p><b>Parole cercate:</b> {$bool}</p>
            <p><b>Testimonianza:</b> {$iter}</p>    
            <p><b>Utterances trovate:</b>{$conta}</p>
            <div>{app:risultatifinalibool($file-path, $bool, $query)}</div>
        </div>
        else ""
};

(: funzione che crea la form per relazione tra blocchi e quantita di termini, singolo testimone :)
declare function app:showform($bool as xs:string*, $numbool as xs:integer?, $iter as xs:string?, $choose as xs:string*){
    <div>
        <form id="showform">
        <p><b>Parole cercate:</b> {$bool}</p><br/>
        <div>
            <p class="pBlock">{"Scegli la relazione tra i due blocchi"}</p>
            <select id="block" name="block" aria-label="Default select example">
            <option value=""/>
            <option value="should">Should</option>
            <option value="must">Must</option>
            </select>
        </div>
        <div class="">
            <p class="pTerm">{"Scegli quanti termini inserire nel primo blocco"}</p>
            <select id="numterm1" name="numterm1" aria-label="Default select example">
            <option value=""/>
            {for $i in 1 to $numbool
            return 
                <option value="{$i}">{$i}</option>}
            </select>
        </div>
        <div>
             <p class="pTerm">{"Scegli quanti termini inserire nel secondo blocco"}</p>
            <select id="numterm2" name="numterm2" aria-label="Default select example">
            <option value=""/>
            {for $i in 1 to $numbool
            return 
                <option value="{$i}">{$i}</option>}
            </select>
        </div>
            {for $i in 1 to ($numbool)
            return
                <input name="choose" value="{$choose[$i]}" type="hidden"/>}
                 {for $i in 1 to ($numbool)
            return
                <input name="bool" value="{$bool[$i]}" type="hidden"/> }
                <input name="iter" value="{$iter}" type="hidden"/>
                <input name="numbool" value="{$numbool}" type="hidden"/>
                <button type="submit" class="btn btn-primary bricerca">Invia</button>
        </form>
        </div>
};

(: funzione che smista la ricerca booleana in base al fatto che l'utente abbia scelto Tutti o solo un testimone :)
declare function app:cercabool($testimonianzasist as xs:string?, $bool as xs:string*, $choose as xs:string*){
    let $numbool := count($bool)
    return
        if ($testimonianzasist != "Tutti")
        then
            let $file-path := concat("/db/apps/proget/xml/",$testimonianzasist,".xml")
            return 
                app:showform($bool, $numbool, $testimonianzasist, $choose)
        else
            <div>{app:showformAll($bool, $numbool, $testimonianzasist, $choose)}</div>
};

(: RICERCA WILDCARD :)

(: funzione che gestisce la ricerca di parole, usando un carattere jolly o wildcard:)
declare %private function app:riswildcard( $nome-autore as xs:string?, $term2 as xs:string?){
    let $file-path := concat("/db/apps/proget/xml/",$nome-autore,".xml")
    let $query := <query>
        <bool><wildcard>{$term2}</wildcard></bool>
        </query>
    return
        for $hit in doc($file-path)//tei:u[ft:query(., $query)]
            for $h in $hit
            let $s := <span>{string($h)}</span>
            let $e := util:expand($h)
            let $xslt := doc("/db/apps/proget/xslt/xsltbool.xsl")
            let $newe := transform:transform($e, $xslt, ())
            return
                <tr>
                    <td class="table">
                    <span>{$newe}</span>
                    </td>
                </tr>
};

(: funzione che stampa i bottoni-collapse :)
declare %private function app:singleCardWildcard($nome-autore as xs:string?, $term as xs:string*, $iter as xs:string? ){
        let $conta := count(app:cercawildcard($term, $iter)//exist:match)
        return
        <div class="card">
            <div class="card-header" id="heading{$iter}">
                <h2 class="mb-0">
                    <button class="btn btn-link collapsed"
                        type="button" data-toggle="collapse"
                        data-target="#collapse{$iter}"
                        aria-expanded="false"
                        aria-controls="collapse{$iter}">
                        {concat($nome-autore," ","(",$conta,")")}
                    </button>
                </h2>
            </div>
            <div id="collapse{$iter}" class="collapse"
                aria-labelledby="heading{$iter}"
                data-parent="#accordionExample">
                <div class="card-body">
                   <table> {app:riswildcard($iter,$term)} </table>
                </div>
            </div>
        </div>
};

(: funzione che gestisce la ricerca wildcard in base al fatto che l'utente abbia scelto Tutti o solo un testimone :)
declare function app:cercawildcard($term as xs:string?, $testimonianzasist as xs:string?){
    if ($testimonianzasist != "Tutti")
    then
        let $file-path := concat("/db/apps/proget/xml/",$testimonianzasist,".xml")
        let $query := <query>
            <bool><wildcard>{$term}</wildcard></bool>
        </query>
        return
            <table>{
            for $hit in doc($file-path)//tei:u[ft:query(., $query)]
            for $h in $hit
            let $s := <span>{string($h)}</span>
            let $e := util:expand($h)
            let $e := util:expand($h)
            let $xslt := doc("/db/apps/proget/xslt/xsltbool.xsl")
            let $newe := transform:transform($e, $xslt, ())
            return
                <tr>
                    <td class="table">
                    <span>{$newe}</span>
                    </td>
                </tr>
                }</table>
    else
        for $xml in collection("/db/apps/proget/xml")/*
            let $testimone := $xml//tei:person[@role = 'testimone']
            let $nome-format0 := concat($testimone/tei:persName/tei:forename, '_', $testimone/tei:persName/tei:surname) (: es. Nedo_Fiano :)
            let $nome-format := replace($nome-format0, '_', ' ')
            return
                <div>{app:singleCardWildcard($nome-format,$term, $nome-format0)}</div>
};

(: funzione che stampa i risultati della ricerca wildcard :)
declare function app:wildcard($testimonianzasist as xs:string?, $term as xs:string?){
    let $contaoccorrenze := count(app:cercawildcard($term, $testimonianzasist)//exist:match)
    return
        if($contaoccorrenze >= 0)
        then 
            <div class="cercawild" id="recap">
            <p><b>Tipo di ricerca:</b> Wildcard </p>
            <p> <b>Parola cercata: </b> {$term}</p>
            <p><b>Testimonianza: </b> {$testimonianzasist}</p>
            <p><b>Parole trovate: </b> {$contaoccorrenze}</p>
            <div  class="accordion" id="accordionExample" >
            {app:cercawildcard($term, $testimonianzasist)}
            </div>
            </div>
        else""
};


(: RICERCA FUZZY :)

(: funzione che calcola i risultati della ricerca fuzzy :)
declare %private function app:risfuzzy( $nome-autore as xs:string?, $term2 as xs:string?){
     let $file-path := concat("/db/apps/proget/xml/",$nome-autore,".xml")
          let $query := <query>
                <bool><fuzzy>{$term2}~</fuzzy></bool>
                </query>
                return
                for $hit in doc($file-path)//tei:u[ft:query(., $query)]
                for $h in $hit
                let $s := <span>{string($h)}</span>
                let $e := util:expand($h)
                let $e := util:expand($h)
                let $xslt := doc("/db/apps/proget/xslt/xsltbool.xsl")
                let $newe := transform:transform($e, $xslt, ())
                return
                <tr>
                    <td class="table">
                    <span>{$newe}</span>
                    </td>
                </tr>
};

(: funzione che stampa i bottoni-collapse :)
declare %private function app:singleCardFuzzy($nome-autore as xs:string?, $term as xs:string*, $iter as xs:string? ){
    let $conta := count(app:fuzzy($term, $iter)//exist:match)
    return
        <div class="card">
            <div class="card-header" id="heading{$iter}">
                <h2 class="mb-0">
                    <!-- data-toggle, data-target, aria-expanded, 
                        aria-controls attributes are used -->
                    <!-- The toggling functionality are intact -->
                    <button class="btn btn-link collapsed"
                        type="button" data-toggle="collapse"
                        data-target="#collapse{$iter}"
                        aria-expanded="false"
                        aria-controls="collapse{$iter}">
                        {concat($nome-autore," ","(",$conta,")")}
                    </button>
                </h2>
            </div>
            <div id="collapse{$iter}" class="collapse"
                aria-labelledby="heading{$iter}"
                data-parent="#accordionExample">
                <div class="card-body">
                   <table>    {app:risfuzzy($iter,$term)}  </table>
                </div>
            </div>
        </div>
    };

(: funzione che gestisce la ricerca fuzzy, basata sull'edit distance :)
declare function app:fuzzy($term as xs:string?, $testimonianzasist as xs:string?){
    if ($testimonianzasist != "Tutti")
    then
        let $file-path := concat("/db/apps/proget/xml/",$testimonianzasist,".xml") 
        let $query := 
        <query>
            <bool><fuzzy>{$term}~</fuzzy></bool>
        </query>
    return
        <table>{
        for $hit in doc($file-path)//tei:u[ft:query(., $query)]
        for $h in $hit
            let $s := <span>{string($h)}</span>
            let $e := util:expand($h)
            let $e := util:expand($h)
            let $xslt := doc("/db/apps/proget/xslt/xsltbool.xsl")
            let $newe := transform:transform($e, $xslt, ())
            return
                <tr>
                    <td class="table">
                    <span>{$newe}</span>
                    </td>
                </tr>
        }</table>
    else
        for $xml in collection("/db/apps/proget/xml")/*
            let $testimone := $xml//tei:person[@role = 'testimone']
            let $nome-format0 := concat($testimone/tei:persName/tei:forename, '_', $testimone/tei:persName/tei:surname) (: es. Nedo_Fiano :)
            let $nome-format := replace($nome-format0, '_', ' ')
            return
             <div>{app:singleCardFuzzy($nome-format,$term, $nome-format0)}</div>
    
};

(: funzione che stampa i risultati della ricerca fuzzy :)
declare function app:ricercafuzzy($testimonianzasist as xs:string?, $term as xs:string?){
    let $conta := count(app:fuzzy($term, $testimonianzasist)//exist:match)
    return
    if($conta >= 0)
    then 
        <div class="cercafuzzy" id="recap">
        <p><b>Tipo di ricerca:</b> Fuzzy </p>
        <p> <b>Parola cercata: </b> {$term}</p>
        <p><b>Testimonianza: </b> {$testimonianzasist}</p>
        <p><b>Parole trovate: </b> {$conta}</p>
        <div  class="accordion" id="accordionExample" >
        {app:fuzzy($term, $testimonianzasist)}
        </div>
        </div>
    else ""
};


(: RICERCA PAROLA ESATTA :)

(: funzione che calcola i risultati della ricerca esatta :)
declare %private function app:risesatta( $nome-autore as xs:string?, $term2 as xs:string?){
     let $file-path := concat("/db/apps/proget/xml/",$nome-autore,".xml")
          let $query := <query>
                <bool><term>{$term2}</term></bool>
                </query>
                return
                for $hit in doc($file-path)//tei:u[ft:query(., $query)]
                for $h in $hit
                let $s := <span>{string($h)}</span>
                let $e := util:expand($h)
                let $e := util:expand($h)
                let $xslt := doc("/db/apps/proget/xslt/xsltbool.xsl")
                let $newe := transform:transform($e, $xslt, ())
                return
                <tr>
                    <td class="table">
                    <span>{$newe}</span>
                    </td>
                </tr>
};

(: funzione che stampa i bottoni-collapse :)
declare %private function app:singleCardEsatta($nome-autore as xs:string?, $term as xs:string*, $iter as xs:string? ){
        let $conta := count(app:esatta($term, $iter)//exist:match)
        return
        <div class="card">
            <div class="card-header" id="heading{$iter}">
                <h2 class="mb-0">
                    <!-- data-toggle, data-target, aria-expanded, 
                        aria-controls attributes are used -->
                    <!-- The toggling functionality are intact -->
                    <button class="btn btn-link collapsed"
                        type="button" data-toggle="collapse"
                        data-target="#collapse{$iter}"
                        aria-expanded="false"
                        aria-controls="collapse{$iter}">
                        {concat($nome-autore," ","(",$conta,")")}
                    </button>
                </h2>
            </div>
            <div id="collapse{$iter}" class="collapse"
                aria-labelledby="heading{$iter}"
                data-parent="#accordionExample">
                <div class="card-body">
                   <table>    { app:risesatta($iter,$term)}  </table>
                </div>
            </div>
        </div>
};
    
(: funzione che gestisce la ricerca esatta in base al fatto che l'utente abbia scelto Tutti o solo un testimone :)
declare function app:esatta($term as xs:string?, $testimonianzasist as xs:string?){
    if ($testimonianzasist != "Tutti")
        then
            let $file-path := concat("/db/apps/proget/xml/",$testimonianzasist,".xml") 
            let $query := <query>
                <bool><term>{$term}</term></bool>
            </query>
            return
            <table>{
            for $hit in doc($file-path)//tei:u[ft:query(., $query)]
            for $h in $hit
                let $s := <span>{string($h)}</span>
                let $e := util:expand($h)
                let $e := util:expand($h)
                let $xslt := doc("/db/apps/proget/xslt/xsltbool.xsl")
                let $newe := transform:transform($e, $xslt, ())
                return
                <tr>
                    <td class="table">
                    <span>{$newe}</span>
                    </td>
                </tr>
            }</table>
    else
        for $xml in collection("/db/apps/proget/xml")/*
            let $testimone := $xml//tei:person[@role = 'testimone']
            let $nome-format0 := concat($testimone/tei:persName/tei:forename, '_', $testimone/tei:persName/tei:surname) (: es. Nedo_Fiano :)
            let $nome-format := replace($nome-format0, '_', ' ')
            return
             <div>{app:singleCardEsatta($nome-format,$term, $nome-format0)}</div>
};

(: funzione che stampa i risultati della ricerca esatta :)
declare function app:ricercaesatta($testimonianzasist as xs:string?, $term as xs:string?){
    let $contaoccorrenze := count(app:esatta($term, $testimonianzasist)//exist:match)
    return
    if($contaoccorrenze > 0)
    then 
        <div class="cercaesatta" id="recap">
        <p><b>Tipo di ricerca:</b> Esatta </p>
        <p> <b>Parola cercata: </b> {$term}</p>
        <p><b>Testimonianza: </b> {$testimonianzasist}</p>
        <p><b>Parole trovate: </b> {$contaoccorrenze}</p>
        <div  class="accordion" id="accordionExample" >
        {app:esatta($term, $testimonianzasist)}
        </div>
        </div>
    else "" 
};


(: testimonianzeScritte :)

declare function app:ricercaScritte($node as node(), $model as map(*), $searchTestScritte as xs:string?, $smistaScritte as xs:string?, $termScritte as xs:string*, $chooseScritte as xs:string*){
    let $testimonianzasist := replace($searchTestScritte, "\d+", "_")
    let $testimonianzasist := replace($testimonianzasist, " ", "_")
    return 
        switch($smistaScritte)
        case "wildcard" return app:wildcardScritte($testimonianzasist, $termScritte)
        case "fuzzy" return app:ricercafuzzyScritte( $testimonianzasist, $termScritte)
        case "esatta" return app:ricercaesattaScritte( $testimonianzasist, $termScritte)
        case "booleana" return app:cercaboolScritte($testimonianzasist, $termScritte, $chooseScritte)
        default return ""
};

declare %private function app:riswildcardScritte( $nome-autore as xs:string?, $term2 as xs:string?){
     let $file-path := concat("/db/apps/proget/xmlscritte/",$nome-autore,".xml")
          let $query := <query>
                <bool><wildcard>{$term2}</wildcard></bool>
                </query>
                return
                for $hit in doc($file-path)//tei:p[ft:query(., $query)]
                for $h in $hit
                let $s := <span>{string($h)}</span>
                let $e := util:expand($h)
                let $e := util:expand($h)
                let $xslt := doc("/db/apps/proget/xslt/xsltbool.xsl")
                let $newe := transform:transform($e, $xslt, ())
                return
                <tr>
                    <td class="table">
                    <span>{$newe}</span>
                    </td>
                </tr>
};

declare %private function app:singleCardWildcardScritte($nome-autore as xs:string?, $term as xs:string*, $iter as xs:string? ){
        let $conta := count(app:cercawildcardScritte($term, $iter)//exist:match)
        return
        <div class="card">
            <div class="card-header" id="heading{$iter}">
                <h2 class="mb-0">
                    <!-- data-toggle, data-target, aria-expanded, 
                        aria-controls attributes are used -->
                    <!-- The toggling functionality are intact -->
                    <button class="btn btn-link collapsed"
                        type="button" data-toggle="collapse"
                        data-target="#collapse{$iter}"
                        aria-expanded="false"
                        aria-controls="collapse{$iter}">
                        {concat($nome-autore," ","(",$conta,")")}
                    </button>
                </h2>
            </div>
            <div id="collapse{$iter}" class="collapse"
                aria-labelledby="heading{$iter}"
                data-parent="#accordionExample">
                <div class="card-body">
                   <table>    { app:riswildcardScritte($iter,$term)}  </table>
                </div>
            </div>
        </div>
};


declare function app:cercawildcardScritte($term as xs:string?, $testimonianzasist as xs:string?){
    if ($testimonianzasist != "Tutti")
    then
    let $file-path := concat("/db/apps/proget/xmlscritte/",$testimonianzasist,".xml")
    let $query := <query>
        <bool><wildcard>{$term}</wildcard></bool>
    </query>
    return
    <table>{
    for $hit in doc($file-path)//tei:p[ft:query(., $query)]
    for $h in $hit
            let $s := <span>{string($h)}</span>
            let $e := util:expand($h)
            let $e := util:expand($h)
            let $xslt := doc("/db/apps/proget/xslt/xsltbool.xsl")
            let $newe := transform:transform($e, $xslt, ())
            return
                <tr>
                    <td class="table">
                    <span>{$newe}</span>
                    </td>
                </tr>
                }</table>
    else
        for $xml in collection("/db/apps/proget/xmlscritte")/*
            let $testimone := $xml//tei:person[@role = 'testimone']
            let $nome-format0 := concat($testimone/tei:persName/tei:forename, '_', $testimone/tei:persName/tei:surname) (: es. Nedo_Fiano :)
            let $nome-format := replace($nome-format0, '_', ' ')
            return
                <div>{app:singleCardWildcardScritte($nome-format,$term, $nome-format0)}</div>
     
};

(: funzione che stampa i risultati della ricerca wildcard :)
declare function app:wildcardScritte(  $testimonianzasist as xs:string?, $term as xs:string?){
    let $contaoccorrenze := count(app:cercawildcardScritte($term, $testimonianzasist)//exist:match)
    return
    if($contaoccorrenze >= 0)
    then 
        <div class="cercawild" id="recap">
        <p><b>Tipo di ricerca:</b> Wildcard </p>
        <p> <b>Parola cercata: </b> {$term}</p>
        <p><b>Testimonianza: </b> {$testimonianzasist}</p>
        <p><b>Parole trovate: </b> {$contaoccorrenze}</p>
        <div  class="accordion" id="accordionExample" >
        {app:cercawildcardScritte($term, $testimonianzasist)}
        </div>
        </div>
    else ""
};

(: RICERCA FUZZY :)
declare %private function app:risfuzzyScritte( $nome-autore as xs:string?, $term2 as xs:string?){
     let $file-path := concat("/db/apps/proget/xmlscritte/",$nome-autore,".xml")
          let $query := <query>
                <bool><fuzzy>{$term2}~</fuzzy></bool>
                </query>
                return
                for $hit in doc($file-path)//tei:p[ft:query(., $query)]
                for $h in $hit
                let $s := <span>{string($h)}</span>
                let $e := util:expand($h)
                let $e := util:expand($h)
                let $xslt := doc("/db/apps/proget/xslt/xsltbool.xsl")
                let $newe := transform:transform($e, $xslt, ())
                return
                <tr>
                    <td class="table">
                    <span>{$newe}</span>
                    </td>
                </tr>
                  
};


declare %private function app:singleCardFuzzyScritte($nome-autore as xs:string?, $term as xs:string*, $iter as xs:string? ){
        let $conta := count(app:fuzzyScritte($term, $iter)//exist:match)
        return
        <div class="card">
            <div class="card-header" id="heading{$iter}">
                <h2 class="mb-0">
                    <!-- data-toggle, data-target, aria-expanded, 
                        aria-controls attributes are used -->
                    <!-- The toggling functionality are intact -->
                    <button class="btn btn-link collapsed"
                        type="button" data-toggle="collapse"
                        data-target="#collapse{$iter}"
                        aria-expanded="false"
                        aria-controls="collapse{$iter}">
                        {concat($nome-autore," ","(",$conta,")")}
                    </button>
                </h2>
            </div>
            <div id="collapse{$iter}" class="collapse"
                aria-labelledby="heading{$iter}"
                data-parent="#accordionExample">
                <div class="card-body">
                   <table>    {app:risfuzzyScritte($iter,$term)}  </table>
                </div>
            </div>
        </div>
};

(: funzione che gestisce la ricerca fuzzy, basata sull'edit distance :)
declare function app:fuzzyScritte($term as xs:string?, $testimonianzasist as xs:string?){
    if ($testimonianzasist != "Tutti")
    then
    let $file-path := concat("/db/apps/proget/xmlscritte/",$testimonianzasist,".xml") 
    let $query := 
    <query>
        <bool><fuzzy>{$term}~</fuzzy></bool>
    </query>
    return
        <table>{
    for $hit in doc($file-path)//tei:p[ft:query(., $query)]
    order by ft:score($hit) descending
    let $expanded := kwic:expand($hit)
    return
        for $match in $expanded//exist:match 
        return
            <tr>
                <td class="table">
                {kwic:get-summary($expanded, $match, <config width="100"/>)}
                </td>
            </tr>}</table>
    else
        for $xml in collection("/db/apps/proget/xmlscritte")/*
            let $testimone := $xml//tei:person[@role = 'testimone']
            let $nome-format0 := concat($testimone/tei:persName/tei:forename, '_', $testimone/tei:persName/tei:surname) (: es. Nedo_Fiano :)
            let $nome-format := replace($nome-format0, '_', ' ')
            return
                <div>{app:singleCardFuzzyScritte($nome-format,$term, $nome-format0)}</div>
};

(: funzione che stampa i risultati della ricerca fuzzy :)
declare function app:ricercafuzzyScritte($testimonianzasist as xs:string?, $term as xs:string?){
    let $conta := count(app:fuzzyScritte($term, $testimonianzasist)//exist:match)
    return
    if($conta >= 0)
    then 
        <div class="cercafuzzy" id="recap">
        <p><b>Tipo di ricerca:</b> Fuzzy </p>
        <p> <b>Parola cercata: </b> {$term}</p>
        <p><b>Testimonianza: </b> {$testimonianzasist}</p>
        <p><b>Parole trovate: </b> {$conta}</p>
        <div  class="accordion" id="accordionExample" >
        {app:fuzzyScritte($term, $testimonianzasist)}
        </div>
        </div>
    else ""
};


declare %private function app:risesattaScritte( $nome-autore as xs:string?, $term2 as xs:string?){
     let $file-path := concat("/db/apps/proget/xmlscritte/",$nome-autore,".xml")
          let $query := <query>
                <bool><term>{$term2}</term></bool>
                </query>
                return
                for $hit in doc($file-path)//tei:p[ft:query(., $query)]
                for $h in $hit
                let $s := <span>{string($h)}</span>
                let $e := util:expand($h)
                let $e := util:expand($h)
                let $xslt := doc("/db/apps/proget/xslt/xsltbool.xsl")
                let $newe := transform:transform($e, $xslt, ())
                return
                <tr>
                    <td class="table">
                    <span>{$newe}</span>
                    </td>
                </tr>
};


declare %private function app:singleCardEsattaScritte($nome-autore as xs:string?, $term as xs:string*, $iter as xs:string? ){
        let $conta := count(app:esattaScritte($term, $iter)//exist:match)
        return
        <div class="card">
            <div class="card-header" id="heading{$iter}">
                <h2 class="mb-0">
                    <!-- data-toggle, data-target, aria-expanded, 
                        aria-controls attributes are used -->
                    <!-- The toggling functionality are intact -->
                    <button class="btn btn-link collapsed"
                        type="button" data-toggle="collapse"
                        data-target="#collapse{$iter}"
                        aria-expanded="false"
                        aria-controls="collapse{$iter}">
                        {concat($nome-autore," ","(",$conta,")")}
                    </button>
                </h2>
            </div>
            <div id="collapse{$iter}" class="collapse"
                aria-labelledby="heading{$iter}"
                data-parent="#accordionExample">
                <div class="card-body">
                   <table>    { app:risesattaScritte($iter,$term)}  </table>
                </div>
            </div>
        </div>
};

declare function app:esattaScritte($term as xs:string?, $testimonianzasist as xs:string?){
    if ($testimonianzasist != "Tutti")
        then
            let $file-path := concat("/db/apps/proget/xmlscritte/",$testimonianzasist,".xml") 
            let $query := <query>
                <bool><term>{$term}</term></bool>
            </query>
            return
            <table>{
            for $hit in doc($file-path)//tei:p[ft:query(., $query)]
            for $h in $hit
                let $s := <span>{string($h)}</span>
                let $e := util:expand($h)
                let $e := util:expand($h)
                let $xslt := doc("/db/apps/proget/xslt/xsltbool.xsl")
                let $newe := transform:transform($e, $xslt, ())
                return
                <tr>
                    <td class="table">
                    <span>{$newe}</span>
                    </td>
                </tr>
            }</table>
    else
        for $xml in collection("/db/apps/proget/xmlscritte")/*
            let $testimone := $xml//tei:person[@role = 'testimone']
            let $nome-format0 := concat($testimone/tei:persName/tei:forename, '_', $testimone/tei:persName/tei:surname) (: es. Nedo_Fiano :)
            let $nome-format := replace($nome-format0, '_', ' ')
            return
                <div>{app:singleCardEsattaScritte($nome-format,$term, $nome-format0)}</div>
        
};

declare function app:ricercaesattaScritte( $testimonianzasist as xs:string?, $term as xs:string?){
    let $contaoccorrenze := count(app:esattaScritte($term, $testimonianzasist)//exist:match)
    return
    if($contaoccorrenze > 0)
    then 
        <div class="cercaesatta" id="recap">
        <p><b>Tipo di ricerca:</b> Esatta </p>
        <p> <b>Parola cercata: </b> {$term}</p>
        <p><b>Testimonianza: </b> {$testimonianzasist}</p>
        <p><b>Parole trovate: </b> {$contaoccorrenze}</p>
        <div  class="accordion" id="accordionExample" >
        
        {app:esattaScritte($term, $testimonianzasist)}
        
        </div>
        </div>
    else "" 
};

(: RICERCA BOOLEANA :)

(: funzione che calcola i risultati della ricerca booleana, tutti i testimoni :)
declare function app:risultatifinaliboolScritteAll($file-path, $bool, $query){
    let $hits := doc($file-path)//tei:p[ft:query(., $query)]
    return
    <table>{(
            <tr><th>{concat('utterances trovate: ',count($hits))}</th></tr>,
            for $hit in $hits 
            order by ft:score($hit) descending
            let $id := $hit/@xml:id
        return
            for $h in $hit
            let $s := <span>{string($h)}</span>
            let $e := util:expand($h)
            let $xslt := doc("/db/apps/proget/xslt/xsltbool.xsl")
            let $newe := transform:transform($e, $xslt, ())
            return
            <tr>
                <td class="table">
                <span class="xmlid">{string($id)}</span><br/>
                <span>{$newe}</span>
                </td>
            </tr>)}</table>
};

(: funzione che calcola i risultati della booleana, singolo testimone :)
declare function app:risultatifinaliboolScritte($file-path, $bool, $query){
    <table>{ 
        for $hit in doc($file-path)//tei:p[ft:query(., $query)]
        order by ft:score($hit) descending
    let $id := $hit/@xml:id
    return
        for $h in $hit
        let $s := <span>{string($h)}</span>
         let $e := util:expand($h)
        let $xslt := doc("/db/apps/proget/xslt/xsltbool.xsl")
        let $newe := transform:transform($e, $xslt, ())
        return
        <tr>
            <td class="table">
            <span class="xmlid">{string($id)}</span><br/>
            <span>{$newe}</span>
            </td>
        </tr>}</table>
};



declare function app:risboolAllScritte($bool as xs:string*, $numbool as xs:integer?, $iter as xs:string?, $choose as xs:string*, $block as xs:string?, $numterm1 as xs:integer?, $numterm2 as xs:integer?){
    let $file-path := concat("/db/apps/proget/xmlscritte/",$iter,".xml")
    let $query := 
    <query>
        <bool>
            <bool occur="{$block}">
                <near ordered="yes" slop="3">{
                for $i in 1 to $numterm1
                return 
                    <term occur="{$choose[$i]}">{$bool[$i]}</term>
                }</near>
            </bool>
            <bool occur="{$block}">
                <near ordered="yes" slop="3">{
                     for $i in 1 to $numterm2
                return 
                    <term occur="{$choose[$i]}">{$bool[$i]}</term>
                }</near>
            </bool>
        </bool>
    </query>
    return
        app:risultatifinaliboolScritteAll($file-path, $bool, $query)
            
};

declare function app:risboolScritte($node as node(), $model as map(*),$bool as xs:string*, $numbool as xs:integer?, $iter as xs:string?, $choose as xs:string*, $block as xs:string?, $numterm1 as xs:integer?, $numterm2 as xs:integer?){
    let $file-path := concat("/db/apps/proget/xmlscritte/",$iter,".xml")
    let $query := 
    <query>
        <bool>
            <bool occur="{$block}">
                <near ordered="yes" slop="3">{
                for $i in 1 to $numterm1
                return 
                    <term occur="{$choose[$i]}">{$bool[$i]}</term>
                }</near>
            </bool>
            <bool occur="{$block}">
                <near ordered="yes" slop="3">{
                     for $i in 1 to $numterm2
                return 
                    <term occur="{$choose[$i]}">{$bool[$i]}</term>
                }</near>
            </bool>
        </bool>
    </query>
    let $conta := count(app:risultatifinaliboolScritte($file-path, $bool, $query)//tr)
    return
        if ($conta > 0)
        then
            
        <div class="cercabool" id="recap">
            <p><b>Tipo di ricerca:</b> Booleana </p>
            <p><b>Parole cercate:</b> {$bool}</p>
            <p><b>Testimonianza:</b> {$iter}</p>    
            <p><b>Utterances trovate:</b>{$conta}</p>
            <div>{app:risultatifinaliboolScritte($file-path, $bool, $query)}</div>
        </div>
        else ""
};

declare function app:singleCardBoolScritte($node as node(), $model as map(*),$boolAllScritte as xs:string*, $numboolAllScritte as xs:integer?, $iterAllScritte as xs:string?, $chooseAllScritte as xs:string*, $blockAllScritte as xs:string?, $numterm1AllScritte as xs:integer?, $numterm2AllScritte as xs:integer?){
    if ($blockAllScritte = "must" or $blockAllScritte = "should")
    then
    <div  class="accordion" id="accordionExample" >{
    for $xml in collection("/db/apps/proget/xmlscritte")/*
                let $testimone := $xml//tei:person[@role = 'testimone']
                let $nome-format0 := concat($testimone/tei:persName/tei:forename, '_', $testimone/tei:persName/tei:surname) (: es. Nedo_Fiano :)
                let $nome-format := replace($nome-format0, '_', ' ')
                return
        let $es := concat("bool[", $numboolAllScritte, "]")
        return
            
            <div class="card">
                <div class="card-header" id="heading{$nome-format0}">
                    <h2 class="mb-0">
                        <!-- data-toggle, data-target, aria-expanded, 
                            aria-controls attributes are used -->
                        <!-- The toggling functionality are intact -->
                        <button class="btn btn-link collapsed"
                            type="button" data-toggle="collapse"
                            data-target="#collapse{$nome-format0}"
                            aria-expanded="false"
                            aria-controls="collapse{$nome-format0}">
                            {$nome-format0}
                        </button>
                    </h2>
                </div>
                
                <div id="collapse{$nome-format0}" class="collapse"
                    aria-labelledby="heading{$nome-format0}"
                    data-parent="#accordionExample">
                <div class="card-body">
                {app:risboolAllScritte($boolAllScritte, $numboolAllScritte, $nome-format0, $chooseAllScritte, $blockAllScritte, $numterm1AllScritte, $numterm2AllScritte)} 
                </div>
                </div>
            </div>}</div>
        else ""
};

declare function app:showformAllScritte($bool as xs:string*, $numbool as xs:integer?, $iter as xs:string?, $choose as xs:string*){
    <div>
        <form id="showform2Scritte">
            <p><b>Parole cercate:</b> {$bool}</p><br/>
            <div>
            <p class="pBlockAll">{"Scegli la relazione tra i due blocchi"}</p>
            <select id="blockAllScritte" name="blockAllScritte" aria-label="Default select example">
            <option value=""/>
            <option value="should">Should</option>
            <option value="must">Must</option>
            </select>
            </div>
            <div>
            <p class="pTermAll">{"Scegli quanti termini inserire nel primo blocco"}</p>
            <select id="numterm1AllScritte" name="numterm1AllScritte" aria-label="Default select example">
            <option value=""/>
            {for $i in 1 to $numbool
            return 
                <option value="{$i}">{$i}</option>}
            </select>
            </div>
            <div>
            <p class="pTermAll">{"Scegli quanti termini inserire nel secondo blocco"}</p>
            <select id="numterm2AllScritte" name="numterm2AllScritte" aria-label="Default select example">
            <option value=""/>
            {for $i in 1 to $numbool
            return 
                <option value="{$i}">{$i}</option>}
            </select>
            </div>
            {for $i in 1 to ($numbool)
            return
                <input name="chooseAllScritte" value="{$choose[$i]}" type="hidden"/>}
                 {for $i in 1 to ($numbool)
            return
                <input name="boolAllScritte" value="{$bool[$i]}" type="hidden"/> }
            <input name="iterAllScritte" value="{$iter}" type="hidden"/>
            <input name="numboolAllScritte" value="{$numbool}" type="hidden"/>
            <button type="submit" class="btn btn-primary bricerca">Invia</button>
        </form>
      
        </div>
};

declare function app:showformScritte($bool as xs:string*, $numbool as xs:integer?, $iter as xs:string?, $choose as xs:string*){
    <div>
        <form id="showformScritte">
        <p><b>Parole cercate:</b> {$bool}</p><br/>
        <div>
            <p class="pBlock">{"Scegli la relazione tra i due blocchi"}</p>
            <select id="block" name="block" aria-label="Default select example">
            <option value=""/>
            <option value="should">Should</option>
            <option value="must">Must</option>
            </select>
        </div>
        <div>
            <p class="pTerm">{"Scegli quanti termini inserire nel primo blocco"}</p>
            <select id="numterm1" name="numterm1" aria-label="Default select example">
            <option value=""/>
            {for $i in 1 to $numbool
            return 
                <option value="{$i}">{$i}</option>}
            </select>
        </div>
        <div>
            <p class="pTerm">{"Scegli quanti termini inserire nel secondo blocco"}</p>
            <select id="numterm2" name="numterm2" aria-label="Default select example">
            <option value=""/>
            {for $i in 1 to $numbool
            return 
                <option value="{$i}">{$i}</option>}
            </select>
        </div>
            {for $i in 1 to ($numbool)
            return
                <input name="choose" value="{$choose[$i]}" type="hidden"/>}
                 {for $i in 1 to ($numbool)
            return
                <input name="bool" value="{$bool[$i]}" type="hidden"/> }
            <input name="iter" value="{$iter}" type="hidden"/>
            <input name="numbool" value="{$numbool}" type="hidden"/>
            <button type="submit" class="btn btn-primary bricerca">Invia</button>
        </form>
      
        </div>
};

declare function app:cercaboolScritte($testimonianzasist as xs:string?, $bool as xs:string*, $choose as xs:string*){
    let $numbool := count($bool)
    return
        if ($testimonianzasist != "Tutti")
        then
            let $file-path := concat("/db/apps/proget/xmlscritte/",$testimonianzasist,".xml")
            
            return 
                  app:showformScritte($bool, $numbool, $testimonianzasist, $choose)
        else
                 <div>{app:showformAllScritte($bool, $numbool, $testimonianzasist, $choose)}</div>
};




(:  :declare function app:booleanaScritte($node as node(), $model as map(*), $testimonianzasist as xs:string?, $boolScritte as xs:string*){
    let $contaoccorrenze := count(app:cercaboolScritte($boolScritte, $testimonianzasist)//exist:match)
    return
    if($contaoccorrenze >= 0)
    then 
        <div class="cercabool" id="recap">
        <p><b>Tipo di ricerca:</b> Booleana </p>
        <p> <b>Parole cercate: </b> {$boolScritte}</p>
        <p><b>Testimonianza: </b> {$testimonianzasist}</p>
        <p><b>Parole trovate: </b> {$contaoccorrenze}</p>
        <div  class="accordion" id="accordionExample" >
        
        {app:cercaboolScritte($boolScritte, $testimonianzasist)}
        
        </div>
        </div>
    else""
};:)

(:  :declare function app:estraiId($node as node(), $model as map(*)){
            for $hit in doc("/db/apps/proget/xml/Edith_Bruck.xml")//tei:u
            let $id := $hit//@xml:id
            where $hit//@xml:id = "e11"
            order by $id 
            return
                <span>{$id}</span>
};:)


(:  :declare function app:estraiId($node as node(), $model as map(*)){
  for $hit in doc("/db/apps/proget/xml/Edith_Bruck.xml")//tei:u
  where $hit/@xml:id = "e11"
  order by $hit
  return 
      <div>
        <b>Utterance restituita:</b><br/>  
        <span>{$hit}</span>
      </div>
};
:)





