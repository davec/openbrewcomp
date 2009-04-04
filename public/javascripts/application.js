function showTeamData(id)
{
  $('team-data_'+id).show();
  $('individual-data_'+id).hide();
}

function showIndividualData(id)
{
  $('individual-data_'+id).show();
  $('team-data_'+id).hide();
}

function toggleOtherClubData(id, other)
{
  var i = $('record_club_'+id).selectedIndex;
  var v = $('record_club_'+id).options[i].value;

  v == other ? $('other-club-data_'+id).show() : $('other-club-data_'+id).hide();
}

function showStyleParams(id)
{
  var i = $('record_style_'+id).selectedIndex;
  var v = $('record_style_'+id).options[i].value.split(',');
  var t = $('record_style_'+id).options[i].text;
  //var category = parseInt(v[1]);
  var classic_style_required = v[2] == 't';
  var base_style_required = v[2] == 't' && /first[- ]time/i.test(t);
  var style_info_required = v[3] == 'r';
  var style_info_optional = v[3] == 'o';
  //var style_info_none = v[3] == 'o';
  var carbonation_required = v[4] == 't';
  var strength_required = v[5] == 't';
  var sweetness_required = v[6] == 't';
  if (base_style_required) {
    // If a first-time entrant is entering a "special" style,
    // show the appropriate sections.
    var eid = $('record_base_style_'+id) ? ('record_base_style_'+id) : ('record_base_style_id_'+id);
    var i2 = $(eid).selectedIndex;
    var v2 = $(eid).options[i2].value.split(',');
    //category = parseInt(v2[1]);
    style_info_required = v2[3] == 'r' || v2[2] == 'r';
    style_info_optional = v2[3] == 'o' || v2[2] == 'o';
    carbonation_required = v2[4] == 't';
    strength_required = v2[5] == 't';
    sweetness_required = v2[6] == 't';
    classic_style_required = false;
  }

  base_style_required ? $('base-style-data_'+id).show() : $('base-style-data_'+id).hide();
  classic_style_required ? $('classic-style-data_'+id).show() : $('classic-style-data_'+id).hide();
  carbonation_required ? $('carbonation-data_'+id).show() : $('carbonation-data_'+id).hide();
  strength_required ? $('strength-data_'+id).show() : $('strength-data_'+id).hide();
  sweetness_required ? $('sweetness-data_'+id).show() : $('sweetness-data_'+id).hide();
  if (style_info_required || style_info_optional) {
    style_info_required ? $('style-info-data_'+id).addClassName('required') : $('style-info-data_'+id).removeClassName('required');
    $('style-info-data_'+id).show();
  } else {
    $('style-info-data_'+id).hide();
  }
}

function showJudgeRankParams(id)
{
  var i = $('record_judge_rank_'+id).selectedIndex;
  var v = $('record_judge_rank_'+id).options[i].value.split(',');
  var t = $('record_judge_rank_'+id).options[i].text;
  var is_bjcp_rank = v[1] == 't';
  if (is_bjcp_rank) {
    $('judge-number-data_'+id).show();
  } else {
    $('judge-number-data_'+id).hide();
  }
}

function toggleTimeAvailability(id)
{
  $(id+'_start_time').disabled = $(id+'_end_time').disabled = !$(id).checked;
}

function toggleAnonLogin()
{
  var u = $('user_login');
  var p = $('user_password');

  u.disabled = p.disabled = !(u.disabled || p.disabled);
}

function toggleDiv(id, step)
{
  $(id).toggle();
  if (step !== undefined && step)
    $(id+'-step-marker').toggleClassName('open');
}

var toggleState = new Object();
function toggleDivWithEffects(id, step)
{
  if (toggleState[id] == 1)
  {
    Effect.BlindUp(id, { duration: 0.5,
                         queue: {scope:'toggle', position:'end'},
                         afterFinish: function(){
                           if (step !== undefined && step)
                             $(id+'-step-marker').removeClassName('open');
                           toggleState[id] = 0;
                         }
                        });
  } else {
    Effect.BlindDown(id, { duration: 0.5,
                           queue: {scope:'toggle', position:'end'},
                           afterFinish: function(){
                             if (step !== undefined && step)
                               $(id + '-step-marker').addClassName('open');
                             toggleState[id] = 1;
                           }
                          });
  }
}

document.cookie = 'TZ=' + (new Date()).getTimezoneOffset() + ';path=/';
