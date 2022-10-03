//= require signature_pad

document.addEventListener('DOMContentLoaded', function(){
  const canvases = document.getElementsByClassName("signature-field-canvas");
  Array.from(canvases).forEach(canvas => {
    const canvas_container_class = canvas.getAttribute('container-class') || 'signature-field-container'
    const container = canvas.closest("."+canvas_container_class)
    const hidden_field = container.getElementsByClassName('signature-field-hidden')[0]
    if(hidden_field){
      const parent_form = hidden_field.closest("form");
      const signaturePad = new SignaturePad(canvas);

      parent_form.onsubmit = function() {
        hidden_field.value = signaturePad.toDataURL()
      }

      function resizeCanvas() {
        var ratio =  Math.max(window.devicePixelRatio || 1, 1);
        canvas.width = canvas.offsetWidth * ratio;
        canvas.height = canvas.offsetHeight * ratio;
        canvas.getContext("2d").scale(ratio, ratio);
        signaturePad.clear();
      }

      window.addEventListener("resize", resizeCanvas, true);
      resizeCanvas();
    }
  })

}, false)