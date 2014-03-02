//
// Validator routines and other form functions
//	Validator - classes and functions for form validation
//	Left/Right widget - 
//      Modified - supports the "form has been modified" banner.
//      Variant - supports variant form.
//      Calendar - the pop-up date selector.
//
//  VALIDATOR
//  --------
//
// CLASSES
//    Validator - holds entry points to methods to control validators.
//                Holds a backpointer to the form object.
//    ValidationSet - attached to form elements.  Holds an array of
//                    ValidationDesc, one for each validation to be
//                    performed on that element.  Also holds a
//                    backpointer to its containing form element.
//    ValidationDesc - holds the name of a single validator to be applied
//                     to the  form element it is associated with,
//                     plus parameters (if any) and a "run" entry point.
//                     Also holds a back pointer to its containing
//                     form element.
//
// ADDITIONAL FORM DATA
//   FORM
//      old_onsubmit - any existing onsubmit handler
//      userValidator - user-defined extra validation routine, if any
//   ELEMENT
//      validationSet - a ValidationSet object
//      
// 
//    
//    <form name="dakafoo"> <!-- any old name -->
//    <!-- any form elements -->
//    </form>
//    
//    <script language="JavaScript" type="text/javascript">
//    
//      var v  = new Validator("dakafoo");
//    
//      v.add("formfield","Label","required");
//      v.add("formfield","Label","range", [min, max]);
//      v.add("formfield","Label","length", [min, max]);
//      v.add("formfield","Label","float");
//      v.add("formfield","Label","signed float");
//      v.add("formfield","Label","unsigned float");
//    

//
// class Validator
// constructor
//
// call with the string form name to validate
//
// class Validator{
//    Object theForm;              // the relevant form
//    void add();                  // add a single validator: addValidator
//    void setUserValidator();
//    void clearAll()
// };
//

function Validator(formname)
{
    this.theForm = document.forms[formname];

    // if there is already an onsubmit handler, save it

    if(this.theForm.onsubmit) {
	this.theForm.old_onsubmit = this.theForm.onsubmit;
	this.theForm.onsubmit=null;
    } else {
	this.theForm.old_onsubmit = null;
    }
    this.theForm.onsubmit = f_submit;
    this.add = v_add;
    this.setUserValidator = v_setUserValidator;
    this.clearAll = v_clearAll;
    this.clearAll();
}

// Validator.add
//
// v_add - user routine to register a validation
//
// element ... name of the form element to validate
// label ... form element label (for message)
// proc ... name of the validation procedure
//

function v_add(element, label, proc, v)
{
    var theElement = this.theForm[element];
    if(!theElement.validationset) {
        theElement.validationset = new ValidationSet(this, label, theElement);
    }
    theElement.validationset.add(proc, v);
}

// Validator.setUserValidator

function v_setUserValidator(functionname)
{
  this.theForm.uservalidator = functionname;
}

// Validator.clearAll

function v_clearAll()
{
    for(var i=0;i < this.theForm.elements.length;i++) {
	this.theForm.elements[i].validationset = null;
    }
}

// Form.submit()
//
// This is called on the SUBMIT POST and "this" refers to the form
//
// For every element in the form, if there is a validator list, run it.

function f_submit()
{
    var message = "";
    for(var i=0 ; i < this.elements.length ; i++) {
	if ( this.elements[i].validationset ) {
	    var txt = this.elements[i].validationset.run();
	    if ( txt.length > 0 ) {
		if ( message.length > 0 ) {
		    message += "\n";
		}
		message += txt;
	    }
	}
    }
    if(this.uservalidator) {
	str =" var ret = "+this.uservalidator+"()";
	eval(str);
	if ( ret.length > 0 ) {
	    if ( message.length > 0 ) {
		message += "\n";
	    }
	    message += txt;
	}
    }
    if ( message.length > 0 ) {
	alert("Input Validation Errors Occurred:\n\n" + message);
	return false;
    } else {
	return true;
    }
}


//
// ValidationSet - constructor for a set of validators for all
//                 form element of a single form
//
// class ValidationSet {
//     Array vSet;
//     void add(()
//     bool run();
//     Object theElement;
//     Object theValidator;
// }

function ValidationSet(v,l,e)
{
    this.vSet = new Array();
    this.add = vs_add;
    this.run = vs_run;
    this.theElement = e;
    this.theValidator = v;
    this.label = l;
}

//
// Validationset.add - add a validator proc to a form
//

function vs_add(proc, v)
{
    this.vSet[this.vSet.length] = new ValidationDesc(this.theElement, proc, v);
}

//
// ValidationSet.run
//
// Run all of the validators for a form
//

function vs_run()
{
    var message = "";
    for(var i=0 ; i < this.vSet.length ; i++ ) {
	var txt = this.vSet[i].run();
	if ( txt.length > 0 ) {
	    if ( message.length == 0 ) {
		message = this.label;
	    }
	    message += "\n- " + txt;
	}
    }
    return message;
}

//
// ValidationDesc - a validation descriptor
//

function ValidationDesc(e, proc, v)
{
    this.proc = proc;
    this.theElement = e;
    this.theElement.emptyok = false;
    this.theValues = v;
    this.run = vdesc_run;
}

// run a single validator for a form element

function vdesc_run()
{
    if ( reBlank.test(this.theElement.value) && this.theElement.emptyok ) {
	return ""; //this.theElement.name + " " + this.theElement.value;
    }
    for ( i=0 ; i<Validators.length ; i++ ) {
	if ( this.proc == Validators[i][0] ) {
	    var msg = "";
	    if ( !Validators[i][1](this, Validators[i][3]) ) {
		var str = Validators[i][2];
		var pieces = str.split(/\$\d+/);
		var macros = str.match(/\$\d+/g);
		if ( macros != null ) {
		    for ( i=0 ; i<macros.length ; i++ ) {
			msg += pieces[i];
			var macnum = macros[i].substr(1);
			if ( macnum <= 0 ) {
			    msg += this.theElement.value;
			} else {
			    msg += this.theValues[macnum-1];
			}
		    }
		    if ( pieces.length > macros.length) {
			msg += pieces[pieces.length-1];
		    }
		} else {
		    msg += str;
		}
		
		// format the string here
		return msg;
	    } else {
		return "";
	    }
	}
    }
    alert("Unknown validator on this page: " + this.proc);
    return "";
}

//
// Validation routines
//

var reBlank = /^\s*$/;
var reFloat = /^((\d+(\.\d*)?)|((\d*\.)?\d+))$/;
var reSignedFloat = /^(((\+|-)?\d+(\.\d*)?)|((\+|-)?(\d*\.)?\d+))$/;
var reEmail = /^.+\@.+(\..+)*$/;
var reInteger = /^\d+$/;
//var reDate = /^\d\d\d\d-\d\d-\d\d$/;
var reDate = /^\d\d\d\d-[01]?\d-[0-3]?\d$/;
var reDatetime = /^\d\d\d\d-[01]?\d-[0-3]?\d [0-2]?\d:[0-5]?\d(?::[0-5]?\d)$/;

var Validators = [
  ["emptyOK",        checkEmpty,   ""],
  ["required",       isRequired,   "Required value, cannot be blank."],
  ["index non-zero", indexNonZero, "Must have a value (currently \"$0\")"],
  ["length",         lengthOf,     "Length must be between $1 and $2"],
  ["float",          doMatch,      "Must be an unsigned  floating point number (Currently \"$0\")", reFloat],
  ["unsigned float", doMatch,      "Must be an unsigned floating point number", reFloat],
  ["signed float",   doMatch,      "Must be a signed floating point number", reSignedFloat],
  ["range",          rangeOf,      "Value must be between $1 and $2" ],
  ["email",          doMatch,      "Must be a valid e-mail address ($0)", reEmail ],
  ["not equal",      notEqual,     "Cannot have this value: $0"],
  ["integer",        doMatch,      "Must be an unsigned integer", reInteger ],
  ["date",           doMatch,      "Must be a date like YYYY-MM-DD", reDate ],
  ["datetime",       doMatch,      "Must be a date-time like YYYY-MM-DD HH:MM:SS", reDatetime ],
];

function checkEmpty(o)
{
    o.theElement.emptyok = true;
    return true;
}

function isRequired(o)
{
    return eval(o.theElement.value.length) > 0;
}

function indexNonZero(o)
{
    return o.theElement.selectedIndex != 0;
}
function lengthOf(o)
{
    return o.theElement.value.length >= o.theValuesv[0] && o.theElement.value.length <= o.theValues[1];
}

function doMatch(o, re)
{
    return re.test(o.theElement.value);
}

function notEqual(o)
{
    var i;
    for ( i=0 ; i<o.theValues.length ; i++ ) {
        if ( o.theElement.value == o.theValues[i] ) {
            return false;
        }
    }
    return true;
}

function rangeOf(o)
{
    return o.theElement.value >= o.theValues[0] && o.theElement.value <= o.theValues[1];
}

//=====================================================================
//
// MODIFIED FORM
// -------------
// These functions support the yellow "form has modified values" bar
//

function modified0(e,n)
{
    var cell = document.getElementById(n);
    cell.style.background = "#ffffbb";
    cell.innerHTML = "Form status: The form has unsaved changes.";
}

function modified1(e,v,n)
{
    var cell = document.getElementById(n);
    if ( e.value != v ) {
        modified0(e,n);
    } else {
        cell.style.background = "#ffffff";
        cell.innerHTML = "Form status: Nothing has changed.";
    }
}

//=====================================================================
//
// VARIANT MANAGEMENT
// ------------------
// These functions support the forms that have elements that turn on and
// off on the client side depending on values put into other elements.
// For example, in the candidate tracker, if the "referrer type" is
// RECRUITER, this will turn on the "Recruiter" form element.
//

function fix_variant(form,sw)
{
    eval ("var ele = document." + form + "." + sw);
    eval ("var list = variant_" + sw);
//alert("type of " + sw + " select = " + ele.type);

    for ( i=0 ; i< list.length ; i++ ) {
	var found = false;

        // for multi-select widgets, if nothing is selected, then enable all
        // variants.

        if ( ele.type == "select-multiple" ) {
            var numselected = 0;
            for ( opt = 0 ; opt<ele.options.length && !found ; opt++ ) {
                if ( ele.options[opt].selected ) {
                    numselected++;
                    for ( j=0 ; j<list[i][1].length && !found ; j++ ) {
                        if ( ele.options[opt].value == list[i][1][j] ) {
                            found = true;
                        }
                    }
                }
            }
            if ( numselected == 0 ) {
                found = true;
            }
        } else {
            for ( j=0 ; j<list[i][1].length && !found ; j++ ) {
	        if ( ele.value == list[i][1][j] ) {
		    found = true;
	        }
            }
	}
        var id = document.getElementById("div_" + form + "_" + list[i][0]);
        if ( id ) {
            if ( found ) {
                id.style.visibility = 'visible';
            } else {
	        id.style.visibility = 'hidden';
            }
	}
    }

}

//==================================================================
//
// CALENDAR
// --------
// These functions support the pop-up date selector
//

var weekend = [0,6];
var weekendColor = "#e0e0e0";
var fontface = "Verdana";
var fontsize = 2;

var gNow = new Date();
var ggWinCal;
isNav = (navigator.appName.indexOf("Netscape") != -1) ? true : false;
isIE = (navigator.appName.indexOf("Microsoft") != -1) ? true : false;

Calendar.Months = ["January", "February", "March", "April", "May", "June",
"July", "August", "September", "October", "November", "December"];

// Non-Leap year Month days..
Calendar.DOMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
// Leap year Month days..
Calendar.lDOMonth = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

function Calendar(p_item, p_WinCal, p_month, p_year, p_format) {
	if ((p_month == null) && (p_year == null))	return;

	if (p_WinCal == null)
		this.gWinCal = ggWinCal;
	else
		this.gWinCal = p_WinCal;
	
	if (p_month == null) {
		this.gMonthName = null;
		this.gMonth = null;
		this.gYearly = true;
	} else {
		this.gMonthName = Calendar.get_month(p_month);
		this.gMonth = new Number(p_month);
		this.gYearly = false;
	}

	this.gYear = p_year;
	this.gFormat = p_format;
	this.gBGColor = "white";
	this.gFGColor = "black";
	this.gTextColor = "black";
	this.gHeaderColor = "black";
	this.gReturnItem = p_item;
}

Calendar.get_month = Calendar_get_month;
Calendar.get_daysofmonth = Calendar_get_daysofmonth;
Calendar.calc_month_year = Calendar_calc_month_year;
Calendar.print = Calendar_print;

function Calendar_get_month(monthNo) {
	return Calendar.Months[monthNo];
}

function Calendar_get_daysofmonth(monthNo, p_year) {
	/* 
	Check for leap year ..
	1.Years evenly divisible by four are normally leap years, except for... 
	2.Years also evenly divisible by 100 are not leap years, except for... 
	3.Years also evenly divisible by 400 are leap years. 
	*/
	if ((p_year % 4) == 0) {
		if ((p_year % 100) == 0 && (p_year % 400) != 0)
			return Calendar.DOMonth[monthNo];
	
		return Calendar.lDOMonth[monthNo];
	} else
		return Calendar.DOMonth[monthNo];
}

function Calendar_calc_month_year(p_Month, p_Year, incr) {
	/* 
	Will return an 1-D array with 1st element being the calculated month 
	and second being the calculated year 
	after applying the month increment/decrement as specified by 'incr' parameter.
	'incr' will normally have 1/-1 to navigate thru the months.
	*/
	var ret_arr = new Array();
	
	if (incr == -1) {
		// B A C K W A R D
		if (p_Month == 0) {
			ret_arr[0] = 11;
			ret_arr[1] = parseInt(p_Year) - 1;
		}
		else {
			ret_arr[0] = parseInt(p_Month) - 1;
			ret_arr[1] = parseInt(p_Year);
		}
	} else if (incr == 1) {
		// F O R W A R D
		if (p_Month == 11) {
			ret_arr[0] = 0;
			ret_arr[1] = parseInt(p_Year) + 1;
		}
		else {
			ret_arr[0] = parseInt(p_Month) + 1;
			ret_arr[1] = parseInt(p_Year);
		}
	}
	
	return ret_arr;
}

function Calendar_print() {
	ggWinCal.print();
}

function Calendar_calc_month_year(p_Month, p_Year, incr) {
	/* 
	Will return an 1-D array with 1st element being the calculated month 
	and second being the calculated year 
	after applying the month increment/decrement as specified by 'incr' parameter.
	'incr' will normally have 1/-1 to navigate thru the months.
	*/
	var ret_arr = new Array();
	
	if (incr == -1) {
		// B A C K W A R D
		if (p_Month == 0) {
			ret_arr[0] = 11;
			ret_arr[1] = parseInt(p_Year) - 1;
		}
		else {
			ret_arr[0] = parseInt(p_Month) - 1;
			ret_arr[1] = parseInt(p_Year);
		}
	} else if (incr == 1) {
		// F O R W A R D
		if (p_Month == 11) {
			ret_arr[0] = 0;
			ret_arr[1] = parseInt(p_Year) + 1;
		}
		else {
			ret_arr[0] = parseInt(p_Month) + 1;
			ret_arr[1] = parseInt(p_Year);
		}
	}
	
	return ret_arr;
}

// This is for compatibility with Navigator 3, we have to create and discard one object before the prototype object exists.
new Calendar();

Calendar.prototype.getMonthlyCalendarCode = function() {
	var vCode = "";
	var vHeader_Code = "";
	var vData_Code = "";
	
	// Begin Table Drawing code here..
	vCode = vCode + "<TABLE BORDER=1 BGCOLOR=\"" + this.gBGColor + "\">";
	
	vHeader_Code = this.cal_header();
	vData_Code = this.cal_data();
	vCode = vCode + vHeader_Code + vData_Code;
	
	vCode = vCode + "</TABLE>";
	
	return vCode;
}

Calendar.prototype.show = function() {
	var vCode = "";
	
	this.gWinCal.document.open();

	// Setup the page...
	this.wwrite("<html>");
	this.wwrite("<head><title>Calendar</title>");
	this.wwrite("</head>");

	this.wwrite("<body " + 
		"link=\"" + this.gLinkColor + "\" " + 
		"vlink=\"" + this.gLinkColor + "\" " +
		"alink=\"" + this.gLinkColor + "\" " +
		"text=\"" + this.gTextColor + "\">");
	this.wwriteA("<FONT FACE='" + fontface + "' SIZE=2><B>");
	this.wwriteA(this.gMonthName + " " + this.gYear);
	this.wwriteA("</B><BR>");

	// Show navigation buttons
	var prevMMYYYY = Calendar.calc_month_year(this.gMonth, this.gYear, -1);
	var prevMM = prevMMYYYY[0];
	var prevYYYY = prevMMYYYY[1];

	var nextMMYYYY = Calendar.calc_month_year(this.gMonth, this.gYear, 1);
	var nextMM = nextMMYYYY[0];
	var nextYYYY = nextMMYYYY[1];
	
	this.wwrite("<TABLE WIDTH='100%' BORDER=1 CELLSPACING=0 CELLPADDING=0 BGCOLOR='#e0e0e0'><TR><TD ALIGN=center>");
	this.wwrite("[<A HREF=\"" +
		"javascript:window.opener.Build(" + 
		"'" + this.gReturnItem + "', '" + this.gMonth + "', '" + (parseInt(this.gYear)-1) + "', '" + this.gFormat + "'" +
		");" +
		"\"><<<\/A>]</TD><TD ALIGN=center>");
	this.wwrite("[<A HREF=\"" +
		"javascript:window.opener.Build(" + 
		"'" + this.gReturnItem + "', '" + prevMM + "', '" + prevYYYY + "', '" + this.gFormat + "'" +
		");" +
		"\"><<\/A>]</TD><TD ALIGN=center>");
	this.wwrite("[<A HREF=\"javascript:window.print();\">Print</A>]</TD><TD ALIGN=center>");
	this.wwrite("[<A HREF=\"" +
		"javascript:window.opener.Build(" + 
		"'" + this.gReturnItem + "', '" + nextMM + "', '" + nextYYYY + "', '" + this.gFormat + "'" +
		");" +
		"\">><\/A>]</TD><TD ALIGN=center>");
	this.wwrite("[<A HREF=\"" +
		"javascript:window.opener.Build(" + 
		"'" + this.gReturnItem + "', '" + this.gMonth + "', '" + (parseInt(this.gYear)+1) + "', '" + this.gFormat + "'" +
		");" +
		"\">>><\/A>]</TD></TR></TABLE><BR>");

	// Get the complete calendar code for the month..
	vCode = this.getMonthlyCalendarCode();
	this.wwrite(vCode);

	this.wwrite("</font></body></html>");
	this.gWinCal.document.close();
}

Calendar.prototype.showY = function() {
	var vCode = "";
	var i;
	var vr, vc, vx, vy;		// Row, Column, X-coord, Y-coord
	var vxf = 285;			// X-Factor
	var vyf = 200;			// Y-Factor
	var vxm = 10;			// X-margin
	var vym;				// Y-margin
	if (isIE)	vym = 75;
	else if (isNav)	vym = 25;
	
	this.gWinCal.document.open();

	this.wwrite("<html>");
	this.wwrite("<head><title>Calendar</title>");
	this.wwrite("<style type='text/css'>\n<!--");
	for (i=0; i<12; i++) {
		vc = i % 3;
		if (i>=0 && i<= 2)	vr = 0;
		if (i>=3 && i<= 5)	vr = 1;
		if (i>=6 && i<= 8)	vr = 2;
		if (i>=9 && i<= 11)	vr = 3;
		
		vx = parseInt(vxf * vc) + vxm;
		vy = parseInt(vyf * vr) + vym;

		this.wwrite(".lclass" + i + " {position:absolute;top:" + vy + ";left:" + vx + ";}");
	}
	this.wwrite("-->\n</style>");
	this.wwrite("</head>");

	this.wwrite("<body " + 
		"link=\"" + this.gLinkColor + "\" " + 
		"vlink=\"" + this.gLinkColor + "\" " +
		"alink=\"" + this.gLinkColor + "\" " +
		"text=\"" + this.gTextColor + "\">");
	this.wwrite("<FONT FACE='" + fontface + "' SIZE=2><B>");
	this.wwrite("Year : " + this.gYear);
	this.wwrite("</B><BR>");

	// Show navigation buttons
	var prevYYYY = parseInt(this.gYear) - 1;
	var nextYYYY = parseInt(this.gYear) + 1;
	
	this.wwrite("<TABLE WIDTH='100%' BORDER=1 CELLSPACING=0 CELLPADDING=0 BGCOLOR='#e0e0e0'><TR><TD ALIGN=center>");
	this.wwrite("[<A HREF=\"" +
		"javascript:window.opener.Build(" + 
		"'" + this.gReturnItem + "', null, '" + prevYYYY + "', '" + this.gFormat + "'" +
		");" +
		"\" alt='Prev Year'><<<\/A>]</TD><TD ALIGN=center>");
	this.wwrite("[<A HREF=\"javascript:window.print();\">Print</A>]</TD><TD ALIGN=center>");
	this.wwrite("[<A HREF=\"" +
		"javascript:window.opener.Build(" + 
		"'" + this.gReturnItem + "', null, '" + nextYYYY + "', '" + this.gFormat + "'" +
		");" +
		"\">>><\/A>]</TD></TR></TABLE><BR>");

	// Get the complete calendar code for each month..
	var j;
	for (i=11; i>=0; i--) {
		if (isIE)
			this.wwrite("<DIV ID=\"layer" + i + "\" CLASS=\"lclass" + i + "\">");
		else if (isNav)
			this.wwrite("<LAYER ID=\"layer" + i + "\" CLASS=\"lclass" + i + "\">");

		this.gMonth = i;
		this.gMonthName = Calendar.get_month(this.gMonth);
		vCode = this.getMonthlyCalendarCode();
		this.wwrite(this.gMonthName + "/" + this.gYear + "<BR>");
		this.wwrite(vCode);

		if (isIE)
			this.wwrite("</DIV>");
		else if (isNav)
			this.wwrite("</LAYER>");
	}

	this.wwrite("</font><BR></body></html>");
	this.gWinCal.document.close();
}

Calendar.prototype.wwrite = function(wtext) {
	this.gWinCal.document.writeln(wtext);
}

Calendar.prototype.wwriteA = function(wtext) {
	this.gWinCal.document.write(wtext);
}

Calendar.prototype.cal_header = function() {
	var vCode = "";
	
	vCode = vCode + "<TR>";
	vCode = vCode + "<TD WIDTH='14%'><FONT SIZE='2' FACE='" + fontface + "' COLOR='" + this.gHeaderColor + "'><B>Sun</B></FONT></TD>";
	vCode = vCode + "<TD WIDTH='14%'><FONT SIZE='2' FACE='" + fontface + "' COLOR='" + this.gHeaderColor + "'><B>Mon</B></FONT></TD>";
	vCode = vCode + "<TD WIDTH='14%'><FONT SIZE='2' FACE='" + fontface + "' COLOR='" + this.gHeaderColor + "'><B>Tue</B></FONT></TD>";
	vCode = vCode + "<TD WIDTH='14%'><FONT SIZE='2' FACE='" + fontface + "' COLOR='" + this.gHeaderColor + "'><B>Wed</B></FONT></TD>";
	vCode = vCode + "<TD WIDTH='14%'><FONT SIZE='2' FACE='" + fontface + "' COLOR='" + this.gHeaderColor + "'><B>Thu</B></FONT></TD>";
	vCode = vCode + "<TD WIDTH='14%'><FONT SIZE='2' FACE='" + fontface + "' COLOR='" + this.gHeaderColor + "'><B>Fri</B></FONT></TD>";
	vCode = vCode + "<TD WIDTH='16%'><FONT SIZE='2' FACE='" + fontface + "' COLOR='" + this.gHeaderColor + "'><B>Sat</B></FONT></TD>";
	vCode = vCode + "</TR>";
	
	return vCode;
}

Calendar.prototype.cal_data = function() {
	var vDate = new Date();
	vDate.setDate(1);
	vDate.setMonth(this.gMonth);
	vDate.setFullYear(this.gYear);

	var vFirstDay=vDate.getDay();
	var vDay=1;
	var vLastDay=Calendar.get_daysofmonth(this.gMonth, this.gYear);
	var vOnLastDay=0;
	var vCode = "";

	/*
	Get day for the 1st of the requested month/year..
	Place as many blank cells before the 1st day of the month as necessary. 
	*/

	vCode = vCode + "<TR>";
	for (i=0; i<vFirstDay; i++) {
		vCode = vCode + "<TD WIDTH='14%'" + this.write_weekend_string(i) + "><FONT SIZE='2' FACE='" + fontface + "'> </FONT></TD>";
	}

	// Write rest of the 1st week
	for (j=vFirstDay; j<7; j++) {
		vCode = vCode + "<TD WIDTH='14%'" + this.write_weekend_string(j) + "><FONT SIZE='2' FACE='" + fontface + "'>" + 
			"<A HREF='#' " + 
				"onClick=\"self.opener.document." + this.gReturnItem + ".value='" + 
				this.format_data(vDay) + 
				"';window.close();\">" + 
				this.format_day(vDay) + 
			"</A>" + 
			"</FONT></TD>";
		vDay=vDay + 1;
	}
	vCode = vCode + "</TR>";

	// Write the rest of the weeks
	for (k=2; k<7; k++) {
		vCode = vCode + "<TR>";

		for (j=0; j<7; j++) {
			vCode = vCode + "<TD WIDTH='14%'" + this.write_weekend_string(j) + "><FONT SIZE='2' FACE='" + fontface + "'>" + 
				"<A HREF='#' " + 
					"onClick=\"self.opener.document." + this.gReturnItem + ".value='" + 
					this.format_data(vDay) + 
					"';window.close();\">" + 
				this.format_day(vDay) + 
				"</A>" + 
				"</FONT></TD>";
			vDay=vDay + 1;

			if (vDay > vLastDay) {
				vOnLastDay = 1;
				break;
			}
		}

		if (j == 6)
			vCode = vCode + "</TR>";
		if (vOnLastDay == 1)
			break;
	}
	
	// Fill up the rest of last week with proper blanks, so that we get proper square blocks
	for (m=1; m<(7-j); m++) {
		if (this.gYearly)
			vCode = vCode + "<TD WIDTH='14%'" + this.write_weekend_string(j+m) + 
			"><FONT SIZE='2' FACE='" + fontface + "' COLOR='gray'> </FONT></TD>";
		else
			vCode = vCode + "<TD WIDTH='14%'" + this.write_weekend_string(j+m) + 
			"><FONT SIZE='2' FACE='" + fontface + "' COLOR='gray'>" + m + "</FONT></TD>";
	}
	
	return vCode;
}

Calendar.prototype.format_day = function(vday) {
	var vNowDay = gNow.getDate();
	var vNowMonth = gNow.getMonth();
	var vNowYear = gNow.getFullYear();

	if (vday == vNowDay && this.gMonth == vNowMonth && this.gYear == vNowYear)
		return ("<FONT COLOR=\"RED\"><B>" + vday + "</B></FONT>");
	else
		return (vday);
}

Calendar.prototype.write_weekend_string = function(vday) {
	var i;

	// Return special formatting for the weekend day.
	for (i=0; i<weekend.length; i++) {
		if (vday == weekend[i])
			return (" BGCOLOR=\"" + weekendColor + "\"");
	}
	
	return "";
}

Calendar.prototype.format_data = function(p_day) {
	var vData;
	var vMonth = 1 + this.gMonth;
	vMonth = (vMonth.toString().length < 2) ? "0" + vMonth : vMonth;
	var vMon = Calendar.get_month(this.gMonth).substr(0,3).toUpperCase();
	var vFMon = Calendar.get_month(this.gMonth).toUpperCase();
	var vY4 = new String(this.gYear);
	var vY2 = new String(this.gYear.substr(2,2));
	var vDD = (p_day.toString().length < 2) ? "0" + p_day : p_day;

	switch (this.gFormat) {
		case "MM\/DD\/YYYY" :
			vData = vMonth + "\/" + vDD + "\/" + vY4;
			break;
		case "MM\/DD\/YY" :
			vData = vMonth + "\/" + vDD + "\/" + vY2;
			break;
		case "MM-DD-YYYY" :
			vData = vMonth + "-" + vDD + "-" + vY4;
			break;
		case "YYYY-MM-DD" :
			vData = vY4 + "-" + vMonth + "-" + vDD;
			break;
		case "MM-DD-YY" :
			vData = vMonth + "-" + vDD + "-" + vY2;
			break;

		case "DD\/MON\/YYYY" :
			vData = vDD + "\/" + vMon + "\/" + vY4;
			break;
		case "DD\/MON\/YY" :
			vData = vDD + "\/" + vMon + "\/" + vY2;
			break;
		case "DD-MON-YYYY" :
			vData = vDD + "-" + vMon + "-" + vY4;
			break;
		case "DD-MON-YY" :
			vData = vDD + "-" + vMon + "-" + vY2;
			break;

		case "DD\/MONTH\/YYYY" :
			vData = vDD + "\/" + vFMon + "\/" + vY4;
			break;
		case "DD\/MONTH\/YY" :
			vData = vDD + "\/" + vFMon + "\/" + vY2;
			break;
		case "DD-MONTH-YYYY" :
			vData = vDD + "-" + vFMon + "-" + vY4;
			break;
		case "DD-MONTH-YY" :
			vData = vDD + "-" + vFMon + "-" + vY2;
			break;

		case "DD\/MM\/YYYY" :
			vData = vDD + "\/" + vMonth + "\/" + vY4;
			break;
		case "DD\/MM\/YY" :
			vData = vDD + "\/" + vMonth + "\/" + vY2;
			break;
		case "DD-MM-YYYY" :
			vData = vDD + "-" + vMonth + "-" + vY4;
			break;
		case "DD-MM-YY" :
			vData = vDD + "-" + vMonth + "-" + vY2;
			break;

		default :
			vData = vMonth + "\/" + vDD + "\/" + vY4;
	}

	return vData;
}

function Build(p_item, p_month, p_year, p_format) {
	var p_WinCal = ggWinCal;
	gCal = new Calendar(p_item, p_WinCal, p_month, p_year, p_format);

	// Customize your Calendar here..
	gCal.gBGColor="white";
	gCal.gLinkColor="black";
	gCal.gTextColor="black";
	gCal.gHeaderColor="darkgreen";

	// Choose appropriate show function
	if (gCal.gYearly)	gCal.showY();
	else	gCal.show();
}

function show_calendar() {
	/* 
		p_month : 0-11 for Jan-Dec; 12 for All Months.
		p_year	: 4-digit year
		p_format: Date format (mm/dd/yyyy, dd/mm/yy, ...)
		p_item	: Return Item.
	*/

	p_item = arguments[0];
	if (arguments[1] == null)
		p_month = new String(gNow.getMonth());
	else
		p_month = arguments[1];
	if (arguments[2] == "" || arguments[2] == null)
		p_year = new String(gNow.getFullYear().toString());
	else
		p_year = arguments[2];
	if (arguments[3] == null)
		p_format = "YYYY-MM-DD";
	else
		p_format = arguments[3];

	vWinCal = window.open("", "Calendar", 
//		"width=250,height=250,status=no,resizable=no,top=200,left=200");
		"width=250,height=250,top=200,left=200");
	vWinCal.opener = self;
	ggWinCal = vWinCal;

	Build(p_item, p_month, p_year, p_format);
}
/*
Yearly Calendar Code Starts here
*/
function show_yearly_calendar(p_item, p_year, p_format) {
	// Load the defaults..
	if (p_year == null || p_year == "")
		p_year = new String(gNow.getFullYear().toString());
	if (p_format == null || p_format == "")
		p_format = "YYYY-MM-DD";

	var vWinCal = window.open("", "Calendar", "scrollbars=yes");
	vWinCal.opener = self;
	ggWinCal = vWinCal;

	Build(p_item, null, p_year, p_format);
}

//==================================================================
//
// RIGHT/LEFT WIDGET
// -----------------
//
// This widget implements a multiselector where the options appear on the
// left and the user can click a right-pointing arrow to move items to the
// right list.
//
function LR_moveup(list) {
	var selected = list.selectedIndex;
	if ( list.length > 0 ) {
		if ( selected > 0 ) {
			var moveText = list[selected].text;
			var moveValue = list[selected].value;
			list[selected].text = list[selected-1].text;
			list[selected].value = list[selected-1].value;
			list[selected-1].text = moveText;
			list[selected-1].value = moveValue;
			list.selectedIndex = selected-1; 
		}
	}
}


function LR_movedown(list) {
	var selected = list.selectedIndex;
	if ( list.length > 0 ) {
		if (selected >= 0 && selected < list.length-1 ) {
			var moveText = list[selected].text;
			var moveValue = list[selected].value;
			list[selected].text = list[selected+1].text;
			list[selected].value = list[selected+1].value;
			list[selected+1].text = moveText;
			list[selected+1].value = moveValue;
			list.selectedIndex = selected+1;
		}
	}
}

function LR_moveSelectedItem(from,to)
{
    for ( var i=0 ; i<from.options.length ; i++ ) {
        if ( from[i].selected ) {
            var myOption = new Option();
            myOption.text = from[i].text;
            myOption.value =  from[i].value;
            to.options[to.options.length] = myOption;
        }
    }

    for ( var i=0 ; i<from.options.length ;  ) {
        if ( from[i].selected ) {
            from[i] = null;
        } else {
            i++;
        }
    }
    from.selectedIndex = -1;
    to.selectedIndex = -1;
}

//    if ( selected >= 0 ) {
//        var myOption = new Option();
//        myOption.text = from[selected].text;
//        myOption.value =  from[selected].value;
//        to.options[to.options.length] = myOption;
//        for ( var i = selected ; i< from.options.length-1 ; i++ ) {
//            from[i].text = from[i+1].text;
//            from[i].value = from[i+1].value;
//        }
//        from.options[from.length-1] = null;
//        from.selectedIndex = -1;
//        to.selectedIndex = -1;
//    }
//}

function LR_buildresult(list, result) {
    result.value = "";
    
    for ( var i=0 ; i<list.length ; i++ ) {
        if ( result.value.length > 0 ) {
            result.value = result.value + ",";
        }
        result.value = result.value + list[i].value;
    }
}
