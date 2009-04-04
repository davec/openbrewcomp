function setScoreColumns(form, id, index)
{
  var i = $('record_'+id+'_judgings_'+index+'_judge_id').selectedIndex;
  var judge_id = $('record_'+id+'_judgings_'+index+'_judge_id').options[i].value;
  var filter = new RegExp('^record_'+id+'_\\d+_'+index+'_judge_id$');
  form.getInputs('hidden').findAll(function(obj) {
    return filter.test(obj.id);
  }).each(function(obj) {
    obj.setAttribute('value', judge_id);
  });
  filter = new RegExp('^record_'+id+'_\\d+_'+index+'_id$');
  form.getInputs('text').findAll(function(obj) {
    return filter.test(obj.id);
  }).each(function(obj) {
    obj.writeAttribute('disabled', !(parseInt(judge_id) > 0));
  });
}

function setJudgePanelRole(id, index, role)
{
  var i = $('record_'+id+'_judgings_'+index+'_judge_id').selectedIndex;
  $('record_'+id+'_judgings_'+index+'_role').setAttribute('value', i > 0 ? role : '');
}

function initJudgePanelRoles(form)
{
  form.getInputs('hidden').findAll(function(obj) {
    return /^record_\d+_judgings_\d+_role$/.test(obj.id);
  }).each(function(obj) {
    setJudgePanelRole(obj.id.replace(/^record_(\d+)_judgings_\d+_role$/, "$1"),
                      obj.id.replace(/^record_\d+_judgings_(\d+)_role$/, "$1"),
                      obj.value);
  });
}

function setJudgingSession(id, select_id)
{
  $(select_id).selectedIndex = $A($(select_id).options).inject(0, function(pos, obj, index) {
     return pos + (obj.value == id ? index : 0);
  });
}

function toggleStaffPoints(id)
{
  var o = $('record_organizer_'+id);
  var s = $('staff-points-data_'+id);
  o.checked ? s.hide() : s.show();
}
