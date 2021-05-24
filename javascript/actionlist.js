// Given a form element for an opening and one for the actions, fix the actions list

// opening - the PK of the opening
// action_item_id - the DOM id of the nect-ation control
// selected_action - the PK of which next-ection should be selected

function fixActionList(opening, action_item_id, selected_action)
{
    action_item = document.getElementById(action_item_id);
    if ( actionmap[opening] ) {
	// remove existing options from the Action menu
	len = action_item.options.length
	for ( var i=len ; i >= 0 ; i-- ) {
	    action_item.remove(i);
	}
	for ( index in actionmap[opening] ) {
	    var action = actions[index];
	    var option = document.createElement('option');
            option.text = actions[actionmap[opening][index]];
	    option.value = actionmap[opening][index];
	    action_item.add(option);
	}
    }
    if ( selected_action ) {
	setSelectedValue(action_item,selected_action);
    }
}
function setSelectedValue(selectObj, valueToSet) {
    for (var i = 0; i < selectObj.options.length; i++) {
        if (selectObj.options[i].value== valueToSet) {
            selectObj.options[i].selected = true;
            return;
        }
    }
}
