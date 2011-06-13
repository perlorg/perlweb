<!DOCTYPE style-sheet PUBLIC "-//James Clark//DTD DSSSL Style Sheet//EN" [
 <!ENTITY docbookdsl PUBLIC
     "-//Norman Walsh//DOCUMENT DocBook HTML Stylesheet//EN" CDATA DSSSL>
]>

<!-- 
  Standard DocBook -> HTML DSSSL Stylesheet

  Online Documentation available at: 
  	http://www.nwalsh.com/docbook/dsssl/doc/

  12/15/00: Adam Turoff; Created
-->

<style-sheet>
 <style-specification use="docbook">
  <style-specification-body>

(define %html-ext% ".html")
(define %section-autolabel% #f)
(define %generate-legalnotice-link% #t)
(define ($legalnotice-link-file$ legalnotice) 
 (string-append "legal"
  (number->string (all-element-number legalnotice))
  %html-ext%))
(define %gentext-nav-use-tables% #t)
(define %shade-verbatim% #t)
(define %use-id-as-filename% #t)
(define %root-filename% "index")
(define html-manifest #f)

;; modified from dbchunk.dsl
;; put the 1st subsection onto a new page
;; (define (chunk-skip-first-element-list) (list))

(define %may-format-variablelist-as-table% #f)
(define %indent-programlisting-lines% "	")
(define %indent-screen-lines% "	")
(define %number-programlisting-lines% #f)

;; don't generate a list of tables
(define ($generate-book-lot-list$) (list))

;; Cut off the TOC at two levels deep
(define (toc-depth nd) 2)

;; Suppress the list of tables
(define (build-lot nd lotgi) (list))


;; add a horizontal rule after every QandA entry
;; TODO: make it intelligent, and do it between 2 QandA entries.
(element qandaentry
  (make element gi: "DIV"
	attributes: (list (list "CLASS" (gi)))
	(process-children)
	(make empty-element gi: "HR"
	  attributes: (list (list "WIDTH" "50%")))))

;; Add a wider horizontal rule ahead of each division

(element qandadiv
  (make element gi: "DIV"
	attributes: (list (list "CLASS" (gi)))
    (make empty-element gi: "HR"
	  attributes: (list (list "WIDTH" "75%")))
	(process-children)))


;; Suppress article titlepages for this doc.
(define %generate-article-titlepage% 
  ;; Should an article title page be produced?
    #f)


(define %linenumber-mod% 1)
(define %linenumber-padchar% " ")

(element warning ($admonition$))
(element (warning title) (empty-sosofo))
(element (warning para) ($admonpara$))
(element (warning simpara) ($admonpara$))
(element caution ($admonition$))
(element (caution title) (empty-sosofo))
(element (caution para) ($admonpara$))
(element (caution simpara) ($admonpara$))

(define en-warning-label-title-sep ": ")
(define en-caution-label-title-sep ": ")

  </style-specification-body>
 </style-specification>

 <external-specification id="docbook" document="docbookdsl">
</style-sheet>
