//
// var cc = new Array();
// cc[opening_id1] = [ user_id, user_id, user_id, ... ];
// cc[opening_id2] = [ user_id, user_id, user_id, ... ];
// user[user_id1] = 'User Name';
// user[user_id2] = 'User Name';
// ...

function setCCList(me)
{
    // Get the job opening that was selected
    var opening = me.value;
    var from = document.form000.cc_list;
    var to = document.form000.cc_selected;
    if ( cc[opening] ) {
	while (to.options.length >0 ) {
	    to.selectedIndex = 0;
	    LR_moveSelectedItem(to,from);
	}
	for ( index in cc[opening] ) {
	    var user = cc[opening][index];
	    for ( var i=0 ; i<from.options.length ; i++ ) {
		if ( from[i].value == user ) {
		    from.selectedIndex = i;
		    LR_moveSelectedItem(from,to);
		    LR_buildresult(to,document.form000.cc);
		}
	    }
	}
    }

}
function setActionList(me)
{
    // Get the job opening that was selected
    var opening_id = me.value;
    var action_form = document.form000.action_id;
    if ( actionmap[opening_id] ) {
	// remove existing options from the Action menu
	len = action_form.options.length
	for ( var i=len ; i >= 0 ; i-- ) {
	    action_form.remove(i);
	}
	for ( index in actionmap[opening_id] ) {
	    var action = actions[index];
	    var option = document.createElement('option');
            option.text = actions[actionmap[opening_id][index]];
	    option.value = actionmap[opening_id][index];
	    action_form.add(option);
	}
    }

}
