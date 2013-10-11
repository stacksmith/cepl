(in-package :cgl)

(defparameter *cached-glsl-source-code* (make-hash-table))
(defparameter *gl-context* (dvals:make-dval))

;; [TODO] Need to be able to delete programs...How does this fit in lisp?

(defparameter *sampler-types*
  '(:isampler-1D :isampler-1d-Array :isampler-2D :isampler-2d-Array
    :isampler-2d-MS :isampler-2d-MS-Array :isampler-2d-Rect
    :isampler-3d :isampler-Buffer :isampler-Cube
    :isampler-Cube-Array :sampler-1D :sampler-1d-Array
    :sampler-1d-Array-Shadow :sampler-1d-Shadow :sampler-2D
    :sampler-2d-Array :sampler-2d-Array-Shadow :sampler-2d-MS
    :sampler-2d-MS-Array :sampler-2d-Rect :sampler-2d-Rect-Shadow
    :sampler-2d-Shadow :sampler-3d :sampler-Buffer :sampler-Cube
    :sampler-Cube-Array :sampler-Cube-Array-Shadow 
    :sampler-Cube-Shadow :usampler-1D :usampler-1d-Array
    :usampler-2D :usampler-2d-Array :usampler-2d-MS
    :usampler-2d-MS-Array :usampler-2d-Rect :usampler-3d 
    :usampler-Buffer :usampler-Cube :usampler-Cube-Array
    :isampler-1D-arb :isampler-1d-Array-arb :isampler-2D-arb 
    :isampler-2d-Array-arb
    :isampler-2d-MS-arb :isampler-2d-MS-Array-arb :isampler-2d-Rect-arb
    :isampler-3d-arb :isampler-Buffer-arb :isampler-Cube-arb
    :isampler-Cube-Array-arb :sampler-1D-arb :sampler-1d-Array-arb
    :sampler-1d-Array-Shadow-arb :sampler-1d-Shadow-arb :sampler-2D-arb
    :sampler-2d-Array-arb :sampler-2d-Array-Shadow-arb :sampler-2d-MS-arb
    :sampler-2d-MS-Array-arb :sampler-2d-Rect-arb :sampler-2d-Rect-Shadow-arb
    :sampler-2d-Shadow-arb :sampler-3d-arb :sampler-Buffer-arb :sampler-Cube-arb
    :sampler-Cube-Array-arb :sampler-Cube-Array-Shadow-arb
    :sampler-Cube-Shadow-arb :usampler-1D-arb :usampler-1d-Array-arb
    :usampler-2D-arb :usampler-2d-Array-arb :usampler-2d-MS-arb
    :usampler-2d-MS-Array-arb :usampler-2d-Rect-arb :usampler-3d-arb
    :usampler-Buffer-arb :usampler-Cube-arb :usampler-Cube-Array-arb))

;;;--------------------------------------------------------------
;;; UNIFORMS ;;;
;;;----------;;;

(defun uniform-1i (location value)
  (gl:uniformi location value))

(defun uniform-sampler (location image-unit)
  (gl:uniformi location image-unit))

(defun uniform-2i (location value)
  (cffi-sys:with-pointer-to-vector-data (ptr value)
    (%gl:uniform-2iv location 1 ptr)))

(defun uniform-3i (location value)
  (cffi-sys:with-pointer-to-vector-data (ptr value)
    (%gl:uniform-3iv location 1 ptr)))

(defun uniform-4i (location value)
  (cffi-sys:with-pointer-to-vector-data (ptr value)
    (%gl:uniform-4iv location 1 ptr)))

(defun uniform-1f (location value)
  (gl:uniformf location value))

(defun uniform-2f (location value)
  (cffi-sys:with-pointer-to-vector-data (ptr value)
    (%gl:uniform-2fv location 1 ptr)))

(defun uniform-3f (location value)
  (cffi-sys:with-pointer-to-vector-data (ptr value)
    (%gl:uniform-3fv location 1 ptr)))

(defun uniform-4f (location value)
  (cffi-sys:with-pointer-to-vector-data (ptr value)
    (%gl:uniform-4fv location 1 ptr)))

(defun uniform-matrix-2ft (location value)
  (cffi-sys:with-pointer-to-vector-data (ptr value)
    (%gl:uniform-matrix-2fv location 1 nil ptr)))

(defun uniform-matrix-3ft (location value)
  (cffi-sys:with-pointer-to-vector-data (ptr value)
    (%gl:uniform-matrix-3fv location 1 nil ptr)))

(defun uniform-matrix-4ft (location value)
  (cffi-sys:with-pointer-to-vector-data (ptr value)
    (%gl:uniform-matrix-4fv location 1 nil ptr)))

(defun uniform-matrix-2fvt (location count value)
  (%gl:uniform-matrix-2fv location count nil value))

(defun uniform-matrix-3fvt (location count value)
  (%gl:uniform-matrix-3fv location count nil value))

(defun uniform-matrix-4fvt (location count value)
  (%gl:uniform-matrix-4fv location count nil value))

;; [TODO] HANDLE DOUBLES
(defun get-foreign-uniform-function (type)
  (case type
    ((:int :int-arb :bool :bool-arb) #'%gl:uniform-1iv)
    ((:float :float-arb) #'%gl:uniform-1fv)
    ((:int-vec2 :int-vec2-arb :bool-vec2 :bool-vec2-arb) #'%gl:uniform-2iv)
    ((:int-vec3 :int-vec3-arb :bool-vec3 :bool-vec3-arb) #'%gl:uniform-3iv)
    ((:int-vec4 :int-vec4-arb :bool-vec4 :bool-vec4-arb) #'%gl:uniform-4iv)
    ((:float-vec2 :float-vec2-arb) #'%gl:uniform-2fv)
    ((:float-vec3 :float-vec3-arb) #'%gl:uniform-3fv)
    ((:float-vec4 :float-vec4-arb) #'%gl:uniform-4fv)
    ((:float-mat2 :float-mat2-arb) #'uniform-matrix-2fvt)
    ((:float-mat3 :float-mat3-arb) #'uniform-matrix-3fvt)
    ((:float-mat4 :float-mat4-arb) #'uniform-matrix-4fvt)
    (t (if (sampler-typep type) nil
           (error "Sorry cepl doesnt handle that type yet")))))

(defun get-uniform-function (type)
  (case type
    ((:int :int-arb :bool :bool-arb) #'uniform-1i)
    ((:float :float-arb) #'uniform-1f)
    ((:int-vec2 :int-vec2-arb :bool-vec2 :bool-vec2-arb) #'uniform-2i)
    ((:int-vec3 :int-vec3-arb :bool-vec3 :bool-vec3-arb) #'uniform-3i)
    ((:int-vec4 :int-vec4-arb :bool-vec4 :bool-vec4-arb) #'uniform-4i)
    ((:float-vec2 :float-vec2-arb) #'uniform-2f)
    ((:float-vec3 :float-vec3-arb) #'uniform-3f)
    ((:float-vec4 :float-vec4-arb) #'uniform-4f)
    ((:float-mat2 :float-mat2-arb) #'uniform-matrix-2ft)
    ((:float-mat3 :float-mat3-arb) #'uniform-matrix-3ft)
    ((:float-mat4 :float-mat4-arb) #'uniform-matrix-4ft)    
    (t (if (sampler-typep type) #'uniform-sampler
           (error "Sorry cepl doesnt handle that type yet")))))

;;;--------------------------------------------------------------
;;; SHADER & PROGRAMS ;;;
;;;-------------------;;;

(defun sampler-typep (type)
  (find type *sampler-types*))

(let ((programs (make-hash-table)))
  (defun program-manager (name)
    (let ((prog-id (gethash name programs)))
      (if prog-id prog-id
          (setf (gethash name programs) (gl:create-program)))))
  (defun program-manager-delete (name)
    (declare (ignore name))
    (print "delete not yet implemented")))

(defun valid-shader-typep (shader)
  (find (first shader) '(:vertex :fragment :geometry)))

(defun extract-textures (uniforms)
  (loop for (name type) in uniforms 
     :if (sampler-typep type)
     :collect name))

(defmacro defsfun (name args &body body)
  (let ((l-args (shader-args-to-list-args args)))
    `(progn
       (when (and (fboundp ',name) (gethash #',name *cached-glsl-source-code*))
         (remhash (symbol-function ',name) *cached-glsl-source-code*))
       (defun ,name ,l-args
         (declare (ignore ,@(loop :for i :in args :for l :in l-args
                               :if (listp args) :collect l)))
         (error "This is an sfun and can only be called from inside a pipeline..for now"))
       (setf (gethash #',name *cached-glsl-source-code*) '(:sfun ,name ,args ,body))
       ',name)))

(defmethod gl-pull ((object function))
  (let* ((code (gethash object *cached-glsl-source-code*))
         (s-type (first code)))
    (if code
        (case s-type
          (:pipeline (error "cant pull pipelines yet"))
          (:shader (let ((code-chunk (third code)))
                     (format nil "~&#~a~%~a" (first code-chunk) (second code-chunk))))
          (:sfun `(defsfun ,(second code) ,(third code)
                    ,@(fourth code))))
        (error "gl-pull can only be used on pipelines, shaders or sfuns"))))

(defmacro defvshader (name args &body body)
  (%defshader name :vertex args body))
(defmacro deffshader (name args &body body)
  (%defshader name :fragment args body))
(defmacro defgshader (name args &body body)
  (%defshader name :geometry args body))

(defmacro defshader (name shader-type args &body body)
  (case shader-type
    (:vertex (%defshader name :vertex args body))
    (:fragment (%defshader name :fragment args body))
    (:geometry (%defshader name :geometry args body))))

(defun shader-args-to-list-args (args)
  (loop :for a :in args :collect
     (if (listp a)
         (first a)
         (if (and (symbolp a) (equal (symbol-name a) "&UNIFORM"))
             '&key
             (error "Invalid atom ~s in shader args" a)))))

(defun subst-sfuns (code)
  (let ((seen nil)
        (sfuncs nil)               
        (sfuns (mapcar #'rest (utils:hash-values *cached-glsl-source-code*))))
    (labels ((wsf (code)
               (when (consp code)
                 (let* ((func (first code))
                        (fdef (and (not (find func seen)) (assoc func sfuns))))
                   (when fdef (push func seen) (push fdef sfuncs))
                   (or (every 'identity (loop :for i :in code :collect (wsf i)))
                       fdef)))))
      (wsf code)
      (loop :until (not (wsf sfuncs)))
      (if sfuncs
          `((labels (,@(loop :for (name args body) :in sfuncs
                          :collect `(,name ,args ,@body)))
              ,@code))
          code))))

;; [TODO] If a shader-func or sfun is redefined as macro or regular func the 
;;        source code still remains in the cache
;; [TODO] if this called before deftype has made it's varjo stuff not cool
;; [TODO] If we load shaders from files the names will clash

(defun %defshader (name type s-args body)
  (let* ((args (shader-args-to-list-args s-args))
         (s-args-with-type (if (find '&context s-args :test #'utils:symbol-name-equal)
                               (append s-args `(:type ,type))
                               (append s-args `(&context :type ,type)))))
    `(progn 
       (defun ,name ,args
         (declare (ignore ,@(remove '&key args)))
         (error "This is a shader stage and can only be called from inside a pipeline..for now"))
       ;; [TODO] how do we handle first shader?
       (setf (gethash #',name *cached-glsl-source-code*) 
             (append (list :shader ',s-args) 
                     (varjo:translate ',s-args-with-type
                                      (subst-sfuns ',body) nil)))
       ',name)))

(defun process-shaders (shaders args)
  (let ((post-compile nil) (result nil))
    (loop :for shader :in shaders :doing
       (if (listp shader)
           (if (eq (first shader) :post-compile)
               (setf post-compile (cons shader post-compile))
               (if (valid-shader-typep shader)
                   (setf result (cons `(quote ,shader) result))
                   (error "Invalid shader type ~s" (first shader))))
           (setf result (cons `(handle-external-shader #',shader ',args) result))))
    (list (reverse result) (reverse post-compile))))

;;
(defun handle-external-shader (lisp-function pipeline-spec)
  (destructuring-bind (cepl-type s-args s-def s-out) 
      (gethash lisp-function *cached-glsl-source-code*)
    (destructuring-bind (shader-type glsl-src) s-def
      )))

;;(HANDLE-EXTERNAL-SHADER #'VS '((VERT VERT-DATA) &UNIFORM (I :INT)))

(defun rolling-translate (args shaders &optional accum (first-shader t))  
  (if (find :type args)
      (error "Varjo: It is invalid to specify a shader type in a program definition")
      (if shaders
          (let* ((shader (first shaders))
                 (type (first shader)))
            (destructuring-bind (glsl new-args)
                (varjo:translate (if (find '&context args 
                                           :test #'utils:symbol-name-equal)
                                     (append args `(:type ,type))
                                     (append args `(&context :type ,type)))
                                 (rest shader) first-shader)
              (rolling-translate new-args (rest shaders) (cons glsl accum) nil)))
          (progn (reverse accum)))))

(defmacro defpipeline (name (&rest args) &body shaders)
  (destructuring-bind (shaders post) (process-shaders shaders args)
    (let* ((uniform-names (mapcar #'first (varjo:extract-uniforms args))))
      `(let ((program nil))
         (defun ,name (stream ,@(when uniform-names `(&key ,@uniform-names)))
           (when (not program)
             (setf program (make-program ,name ,args ,(cons 'list shaders)))
             ,@post)
           (funcall program stream ,@(loop for name in uniform-names 
                                        :append `(,(utils:kwd name)
                                                   ,name))))))))


;; dont forget if not symbol then need to run check for sfuns
(defmacro defpipeline2 (name (&rest args) &body shaders)
  (let* ((uniforms (varjo:extract-uniforms args))
         (textures (extract-textures uniforms))
         (uniform-names (mapcar #'first uniforms))
         (image-unit -1)
         (src->prog-id '*YOU_HAVENT_IMPLEMENTED_THIS*))
    `(progn
       (let ((program-id nil)
             ,@(loop :for uni-p :in uniform-positions :collect
                  :for i :from 0 
                  `(,(utils:symb 'uniform- i) ,uni-p)));;;;THIS NEEDS FIXING!
         (defun ,(symb '%%- name)
             )
         (if (value *gl-context*)
             ,src->prog-id
             (dvals:bind program-id *gl-context* ,src->prog-id))
         (defun ,name (stream ,@(when uniforms `(&key ,@uniform-names)))
           (when stream (no-bind-draw-one stream))
           stream))
       (setf (gethash #',name *cached-glsl-source-code*) ,glsl-src))))

(defmacro make-program (name args shaders)  
  (let* ((uniforms (varjo:extract-uniforms args))
         (textures (extract-textures uniforms))
         (uniform-names (mapcar #'first uniforms))
         (image-unit -1))
    `(let* ((glsl-src (varjo:rolling-translate ',args ,shaders))
            (shaders (loop for (type code) in glsl-src
                        :collect (make-shader type code)))
            (program-id (link-shaders 
                         shaders
                         ,(if name
                              `(program-manager ',name)
                              `(gl:create-program))))
            (assigners (create-uniform-assigners 
                        program-id ',uniforms 
                        ,(utils:kwd (package-name (symbol-package name)))))
            ,@(loop :for name :in uniform-names :for i :from 0
                 :collect `(,(utils:symb name '-assigner)
                             (nth ,i assigners))))
       (declare (ignorable assigners))
       (when cgl::*cached-glsl-source-code* 
         (setf (gethash #',name cgl::*cached-glsl-source-code*) glsl-src))
       (mapcar #'%gl:delete-shader shaders)
       (unbind-buffer)
       (force-bind-vao 0)
       (force-use-program 0)
       (lambda (stream ,@(when uniforms `(&key ,@uniform-names)))
         (use-program program-id)
         ,@(loop :for uniform-name :in uniform-names
              :for uspec :in uniforms
              :collect
              (if (find uniform-name textures)
                  (progn 
                    (incf image-unit)
                    `(if ,uniform-name
                         (if (eq (sampler-type ,uniform-name)
                                 ,(second uspec))
                             (progn
                               (active-texture-num ,image-unit)
                               (bind-texture ,uniform-name)
                               (dolist (fun ,(utils:symb uniform-name '-assigner))
                                 (funcall fun ,image-unit)))
                             (error "incorrect texture type passed to shader"))
                         (error "Texture uniforms must be populated"))) ;really? - for now yeah
                  `(when ,uniform-name
                     (dolist (fun ,(utils:symb uniform-name
                                               '-assigner))
                       (funcall fun ,uniform-name)))))
         (when stream (no-bind-draw-one stream))))))


;; make this return list of funcs or nil for each uni-var
;; package is the package the pipeline is defined in
(defun create-uniform-assigners (program-id uniform-vars package)
  ;; uniform details returns (list name type size) given a prog
  ;; active-uniform-details is in the form:
  ;;               ("glname" (byte-offset principle-type length)...)
  "Collect uniform details from opengl for the program, aggregate the 
   information in a list for each uniform-var. We then pass over each
   uniform and for each uniform part (remember a struct can have many
   parts) we create a function that will take a value *or* pointer 
   and send the data to the correct place in the shader."
  (let ((active-uniform-details 
         (process-uniform-details (program-uniforms program-id)
                                  uniform-vars
                                  package)))
    (loop :for a-uniform :in active-uniform-details :collect
       (destructuring-bind (lisp-name gl-name &rest unif-details) a-uniform
         (let ((location (gl:get-uniform-location program-id gl-name)))
           (if (< location 0)
               (error "uniform ~a not found, this is a bug in cepl" gl-name)
               (loop :for part :in unif-details :collect 
                  (destructuring-bind (offset type length) part
                    (if (or (> length 1) (varjo:type-struct-p type))
                        (lambda (pointer)
                          (funcall (get-foreign-uniform-function type)
                                   location length
                                   (cffi-sys:inc-pointer pointer offset)))
                        (lambda (value) (funcall (get-uniform-function type)
                                                 location value)))))))))))

;; [TODO] Got to be a quicker and tidier way
(defun process-uniform-details (uniform-details uniform-vars package)
  ;; uniform details in-form (name type size) 
  "Uniform-details contains one entry for each uniform BUT some uniforms have
   multiple parts, a single struct may return multiple uniform entries.
   Here we amalagamte the details together under a single symbol name.
   We can then run through the uniform names passed in and find the single
   list of information on that given uniform argument. 
   For each symbol we get a list with the opengl name followed by multiple
   (byte-offset principle-type length) triples."
  (labels ((uniform-type (name)
             (or (second (assoc (symbol-name name) uniform-vars
                                :key #'symbol-name :test #'equal))
                 (error "Could not find the uniform variable named '~a'" name))))
    (let ((result (make-hash-table)))
      (loop :for detail :in uniform-details :do
         (destructuring-bind (d-name d-type d-size) detail
           (let* ((path (parse-uniform-path detail package))
                  (first-name-in-path (caar path))
                  (current-details (rest (gethash first-name-in-path result))))
             (setf (gethash first-name-in-path result)
                   `(,d-name (,(get-path-offset path (uniform-type 
                                                      first-name-in-path))
                               ,d-type ,d-size) ,@current-details)))))
      (loop :for var :in uniform-vars
         :if (gethash (first var) result)
         :collect (cons var (gethash (first var) result))))))

(defun parse-uniform-path (uniform-detail package)
  "Take a string uniform path from opengl and parse it into a list 
of pairs so that jam[10].toast would become ((jam 10) (toast 0))"
  (labels ((s-dot (x) (split-sequence:split-sequence #\. x))
           (s-square (x) (split-sequence:split-sequence #\[ x)))
    (loop for path in (s-dot (first uniform-detail)) :collect
         (destructuring-bind (name &optional array-length) 
             (s-square (remove #\] path))
           (list (symbol-munger:camel-case->lisp-symbol name package)
                 (if array-length (parse-integer array-length) 0))))))

(defun get-slot-type (parent-type slot-name)
  (second (assoc slot-name (varjo:struct-definition parent-type))))



;; * collect all opengl names
;; * Run this on the glsl for each name
;; * feed it through the tools we have
;; * we can then know what we need for each uniform
(defun try-thing (uniform-args glsl-shaders package)
  "[0] merge all shaders into on text
[1] flesh out all the uniforms to full varjo types
[2] For each instance of the gl version of the name in
    the merged-text take the extracted text 'path' and
    parse it into a lisp pair list. This can then be 
    used along with the uniform dat we already have to
    calculate the byte offset into the c-data we need
    to upload from."
  (let ((merged-shaders (format nil "~{~a~}" glsl-shaders))) ;;[0]
    (loop :for uniform :in uniform-args :collect 
       (destructuring-bind (lisp-name varjo-type glsl-name place) 
           (varjo::flesh-out-arg uniform) ;[1]
         (declare (ignorable lisp-name varjo-type glsl-name place))
         (loop :for (start end) 
            :on (cl-ppcre:all-matches (format nil "~a(.*?)[, \(\)]" glsl-name)
                                      merged-shaders) :by #'cddr :collect ;[2]
            (let ((path (parse-uniform-path (list (subseq merged-shaders 
                                                          start (1- end))) 
                                            package))
                  (uniform-type (second uniform)))
              (get-path-offset path uniform-type)))))))

;; ok so more problems are coming. If the path includes an array e.g.
;; jam[i].toast[2]
;; Because the i is uncertain we need to be able to handle the whole array.
;; potentially a position for every element of the arry and every field of every
;; element of the array.


;; [TODO] If type is non cffi then cffi:foreign-type-size will fail.
;;        The array & struct check we dont foreign-type-size a sampler.
;;        Does this need cleaning?
(defun get-path-offset (lisp-uniform-path uniform-type)
  (let ((array-length (second (first lisp-uniform-path))))
    (if (or (> array-length 1) (varjo:type-struct-p uniform-type))
        (let ((child-type uniform-type) (type-b nil))
          (loop :for (slot-name array-length) :in (rest lisp-uniform-path)
             :do (setf type-b child-type
                       child-type (varjo:type-principle 
                                   (get-slot-type child-type slot-name)))
             :sum (+ (cffi:foreign-slot-offset type-b slot-name) 
                     (* (cffi:foreign-type-size child-type) 
                        array-length))))
        0)))

(defun program-attrib-count (program)
  "Returns the number of attributes used by the shader"
  (gl:get-program program :active-attributes))

(defun program-attributes (program)
  "Returns a list of details of the attributes used by
   the program. Each element in the list is a list in the
   format: (attribute-name attribute-type attribute-size)"
  (loop for i from 0 below (program-attrib-count program)
     collect (multiple-value-bind (size type name)
                 (gl:get-active-attrib program i)
               (list name type size))))

(defun program-uniform-count (program)
  "Returns the number of uniforms used by the shader"
  (gl:get-program program :active-uniforms))

(defun program-uniforms (program-id)
  "Returns a list of details of the uniforms used by
   the program. Each element in the list is a list in the
   format: (uniform-name uniform-type uniform-size)"
  (loop for i from 0 below (program-uniform-count program-id)
     collect (multiple-value-bind (size type name)
                 (gl:get-active-uniform program-id i)
               (list name type size))))

(let ((program-cache nil))
  (defun use-program (program-id)
    (unless (eq program-id program-cache)
      (gl:use-program program-id)
      (setf program-cache program-id)))
  (defun force-use-program (program-id)
    (gl:use-program program-id)
    (setf program-cache program-id)))
(setf (documentation 'use-program 'function) 
      "Installs a program object as part of current rendering state")

;; [TODO] Expand on this and allow loading on strings/text files for making 
;;        shaders
(defun shader-type-from-path (path)
  "This uses the extension to return the type of the shader.
   Currently it only recognises .vert or .frag files"
  (let* ((plen (length path))
         (exten (subseq path (- plen 5) plen)))
    (cond ((equal exten ".vert") :vertex-shader)
          ((equal exten ".frag") :fragment-shader)
          (t (error "Could not extract shader type from shader file extension (must be .vert or .frag)")))))

(defun make-shader 
    (shader-type source-string &optional (shader-id (gl:create-shader 
                                                     shader-type)))
  "This makes a new opengl shader object by compiling the text
   in the specified file and, unless specified, establishing the
   shader type from the file extension"
  (gl:shader-source shader-id source-string)
  (gl:compile-shader shader-id)
  ;;check for compile errors
  (when (not (gl:get-shader shader-id :compile-status))
    (error "Error compiling ~(~a~): ~%~a~%~%~a" 
           shader-type
           (gl:get-shader-info-log shader-id)
           source-string))
  shader-id)

(defun load-shader (file-path 
                    &optional (shader-type 
                               (shader-type-from-path file-path)))
  (restart-case
      (make-shader (utils:file-to-string file-path) shader-type)
    (reload-recompile-shader () (load-shader file-path
                                             shader-type))))

(defun load-shaders (&rest shader-paths)
  (mapcar #'load-shader shader-paths))

(defun link-shaders (shaders &optional program_id)
  "Links all the shaders provided and returns an opengl program
   object. Will recompile an existing program if ID is provided"
  (let ((program (or program_id (gl:create-program))))
    (loop for shader in shaders
       do (gl:attach-shader program shader))
    (gl:link-program program)
    ;;check for linking errors
    (if (not (gl:get-program program :link-status))
        (error (format nil "Error Linking Program~%~a" 
                       (gl:get-program-info-log program))))
    (loop :for shader :in shaders :do
       (gl:detach-shader program shader))
    program))

;; [TODO] Need to sort gpustream indicies thing
(defun no-bind-draw-one (stream)
  "This draws the single stream provided using the currently 
   bound program. Please note: It Does Not bind the program so
   this function should only be used from another function which
   is handling the binding."
  (let ((index-type (vertex-stream-index-type stream)))
    (bind-vao (vertex-stream-vao stream))
    (if index-type
        (%gl:draw-elements (vertex-stream-draw-type stream)
                           (vertex-stream-length stream)
                           (gl::cffi-type-to-gl index-type)
                           (make-pointer 0))
        (%gl:draw-arrays (vertex-stream-draw-type stream)
                         (vertex-stream-start stream)
                         (vertex-stream-length stream)))))
