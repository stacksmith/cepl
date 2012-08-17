;; This is a stack of useful functions not really thought of as
;; tools for writing games specifically, but rather for writing
;; cepl. 
;; Saying that though, any use is wonderful so enjoy.

(in-package :cepl-utils)

;; This will be pretty inefficient, but shoudl be fine for code trees
(defun walk-replace (to-replace replace-with form)
  "This walks a list tree ('form') replacing all occurences of 
   'to-replace' with 'replace-with'. This is pretty inefficent
   but will be fine for macros."
  (cond ((null form) nil)
	((atom form) (if (eql form to-replace)
			 replace-with
			 form))
	(t (cons (walk-replace to-replace 
			       replace-with 
			       (car form)) 
		 (walk-replace to-replace 
			       replace-with 
			       (cdr form))))))

(defun file-to-string (path)
  "Sucks up an entire file from PATH into a freshly-allocated 
   string, returning two values: the string and the number of 
   bytes read."
  (with-open-file (s path)
    (let* ((len (file-length s))
           (data (make-string len)))
      (values data (read-sequence data s)))))

(defun flatten (x)
  "Walks a list tree and flattens it (returns a 1d list 
   containing all the elements from the tree)"
  (labels ((rec (x acc)
             (cond ((null x) acc)
                   ((atom x) (cons x acc))
                   (t (rec (car x)
                           (rec (cdr x) acc))))))
    (rec x nil)))


(defun mkstr (&rest args)
  "Takes a list of strings or symbols and returns one string
   of them concatenated together. For example:
    CEPL-EXAMPLES> (cepl-utils:mkstr 'jam 'ham')
     'JAMHAM'
    CEPL-EXAMPLES> (cepl-utils:mkstr 'jam' 'ham')
     'jamham'"
  (with-output-to-string (s)
    (dolist (a args) (princ a s))))

(defun symb (&rest args)
  "This takes a list of symbols (or strings) and outputs one 
   symbol.
   If the input is symbol/s then the output is a regular symbol
   If the input is string/s, then the output is
   a |symbol like this|"
  (values (intern (apply #'mkstr args))))

(defun make-keyword (&rest args)
  "This takes a list of symbols (or strings) and outputs one 
   keyword symbol.
   If the input is symbol/s then the output is a regular keyword
   If the input is string/s, then the output is
   a :|keyword like this|"
  (values (intern (apply #'mkstr args) "KEYWORD")))

(defun group (source n)
  "This takes a  flat list and emit a list of lists, each n long
   containing the elements of the original list"
  (if (zerop n) (error "zero length"))
  (labels ((rec (source acc)
	     (let ((rest (nthcdr n source)))
	       (if (consp rest)
		   (rec rest (cons (subseq source 0 n)
				   acc))
		   (nreverse (cons source acc))))))
    (if source 
	(rec source nil) 
	nil)))

(defvar safe-read-from-string-blacklist
  '(#\# #\: #\|))

(let ((rt (copy-readtable nil)))
  (defun safe-reader-error (stream closech)
    (declare (ignore stream closech))
    (error "safe-read-from-string failure"))

  (dolist (c safe-read-from-string-blacklist)
    (set-macro-character
      c #'safe-reader-error nil rt))

  (defun safe-read-from-string (s &optional fail)
    (if (stringp s)
      (let ((*readtable* rt) *read-eval*)
        (handler-bind
          ((error (lambda (condition)
                    (declare (ignore condition))
                    (return-from
                      safe-read-from-string fail))))
          (read-from-string s)))
      fail)))

(defun sub-at-index (seq index new-val)
  (append (subseq seq 0 index)
	  (list new-val)
	  (subseq seq (1+ index))))

;;; The following util was taken from SBCL's
;;; src/code/*-extensions.lisp

(defun symbolicate-package (package &rest things)
  "Concatenate together the names of some strings and symbols,
producing a symbol in the current package."
  (let* ((length (reduce #'+ things
                         :key (lambda (x) (length (string x)))))
         (name (make-array length :element-type 'character)))
    (let ((index 0))
      (dolist (thing things (values (intern name package)))
        (let* ((x (string thing))
               (len (length x)))
          (replace name x :start1 index)
          (incf index len))))))