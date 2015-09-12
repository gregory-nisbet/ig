(require 'cl-lib)

;; symbols that we use
;; ig-prefix-marker ig-control ig-meta ig-shift

;; there has to be a better way to test equality for something of depth 1.
;; we shall see

(setf ig-table (make-hash-table :test equal))

;; ig-prefix-marker is teh prefix-marker.

(defun ig-prefixes (collection &optional empty? last?)
  "get list of prefixes of string"
  (cl-loop for i
	   from (if empty? 0 1) 
	   to (if last? (length collection) (1- (length collection)))
	   collect (cl-subseq collection 0 i)))

(defun ig-insert (needle func haystack)
  "insert needle into haystack, adding prefix entries as necessary"
  ;; insert prefix-markers in all prefix
  ;; locations
  (let ((prefixes (ig-prefixes needle)))
    (mapcar (lambda (prefix)
	      ;; every prefix is either nil or already a prefix
	      ;; if you encounter a function you are hosed
	      (cl-assert
	       (let ((el (gethash prefix ig-table)))
		 (or (equal el 'ig-prefix-marker) (equal el nil))))
	      ;; insert a new prefix marker into the table
	      (puthash prefix 'ig-prefix-marker haystack)) prefixes))
  ;; insert new function into hash table
  (puthash needle func haystack))

(ig-insert '("t" "u") #'recenter-top-bottom ig-table)
