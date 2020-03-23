/*##################################################################################################
##
##  Nexgen Advanced Ban Manager version 1.02
##  Copyright (C) 2013 Patrick "Sp0ngeb0b" Peltzer
##
##  This program is free software; you can redistribute and/or modify
##  it under the terms of the Open Unreal Mod License version 1.1.
##
##  Contact: spongebobut@yahoo.com | www.unrealriders.de
##
##################################################################################################*/
class NexgenABMWarnDialog extends NexgenPopupDialog;

#exec TEXTURE IMPORT NAME=warnIcon   FILE=Resources\warn.pcx   GROUP="GFX" FLAGS=3 MIPS=OFF

var UMenuLabelControl captionLabel;               // Caption label with adminname.
var UMenuLabelControl reasonLabel;                // Warn reason label 1.
var UMenuLabelControl reasonLabel2;               // Warn reason label 2.

var UWindowSmallButton MycloseButton;             // Our custom close button

var UWindowCheckbox bRead;                        // Checkbox

var localized string notifyInfo;                  // String at bottom

var float imageWidth;                             // Width of the texture

const wrapTextureLen = 55;                        // WrapLength of text next to the Image
const defaultCheckboxWidth = 250;



/***************************************************************************************************
 *
 *  $DESCRIPTION  Creates the dialog. Calling this function will setup the static dialog contents.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function created() {
	local float cy;

	super.created();

	// Add components.
	cy = borderSize;
	
	addImageBox(cy, Texture'warnIcon', 64, 64, true);

	captionLabel = addLabel(cy);
	addNewLine(cy);
	reasonLabel = addLabel(cy);
	reasonLabel2 = addLabel(cy);
	addNewLine(cy);
	addNewLine(cy);
	addNewLine(cy);
	addText(notifyInfo, cy, F_Normal, TA_Left);
	
	MycloseButton = addButton("Close");
	bRead = addCheckbox("I've read and understood this warning.", 215.0,TA_Left);
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Adds a new image box component to the dialog.
 *  $PARAM        yPos  Vertical position on the dialog where the text will be added.
 *  $PARAM        image  Texture to display on the component.
 *  $PARAM        bStretch  Whether or not the image should be streched.
 *  $PARAM        width  Width of the image in pixel.
 *  $PARAM        height Height of the image in pixel.
 *  $REQUIRE      0 <= currRegion && currRegion < regionCount
 *  $RETURN       The image box added to the dialog.
 *  $ENSURE       result != none
 *
 **************************************************************************************************/
function NexgenImageControl addImageBox(float yPos, Texture image, float width, float height,
                                        optional bool bStretch) {
  local float cx, cy, cw, ch;
  local NexgenImageControl imageBox;

	// Initialze position & dimensions.
	cx = borderSize;
	cy = yPos;
	cw = width;
	ch = height;
	yPos += ch;
	
	imageWidth = width;
	
	imageBox = NexgenImageControl(createControl(class'NexgenImageControl', cx, cy, cw, ch));
  imageBox.image = image;
  imageBox.bStretch = bStretch;

	return imageBox;
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Adds a new label component to the dialog (next to the image).
 *  $PARAM        yPos  Vertical position on the dialog where the text will be added.
 *  $REQUIRE      yPos >= 0
 *  $RETURN       The label that has been added to the dialog.
 *  $ENSURE       result != none
 *
 **************************************************************************************************/
function UMenuLabelControl addLabel(out float yPos) {
	local float cx, cy, cw, ch;
  
  // Initialze position & dimensions.
  cx = borderSize + imageWidth + 8;
	cy = yPos;
	cw = winWidth - 2.0 * borderSize;
	ch = labelHeight;
	yPos += ch;

	// Create label.
	return UMenuLabelControl(createControl(class'UMenuLabelControl', cx, cy, cw, ch));
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Sets the contents for this dialog.
 *  $PARAM        reason  Reason why the player was banned.
 *  $PARAM        period  The period for which the player is banned.
 *  $PARAM        str3  Not used.
 *  $PARAM        str4  Not used.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function setContent(optional string reason, optional string adminName, optional string str3, optional string str4) {
  local int wrapPos;

	captionLabel.setText("You have been warned by"@adminName);
	captionLabel.Font = F_Bold;
	
	if(len(reason) < wrapTextureLen) {
	  reasonLabel.setText(reason);
	} else {
	
   wrapPos = getWrapPosition(reason, wrapTextureLen);
   reasonLabel.setText(left(reason, wrapPos));
   reasonLabel2.setText(mid(reason, wrapPos+1));
  }
	reasonLabel.Font = F_Bold;
	reasonLabel2.Font = F_Bold;
	
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Notifies the dialog of an event (caused by user interaction with the interface).
 *                This function will only check if the close button has been clicked.
 *  $PARAM        control    The control object where the event was triggered.
 *  $PARAM        eventType  Identifier for the type of event that has occurred.
 *  $REQUIRE      control != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
function notify(UWindowDialogControl control, byte eventType){
  local NexgenABMClient xClient;

	super.notify(control, eventType);

	if (control == bRead && eventType == DE_Click) {
	
		// Get client controller.
    xClient = NexgenABMClient(client.getController(class'NexgenABMClient'.default.ctrlID));
  	
	  xClient.ReadWarning(bRead.bChecked);
  }
	
	if (control == MycloseButton && eventType == DE_Click) {
    if(bRead.bChecked) {
		  close();
    }
	}
}



/***************************************************************************************************
 *
 *  $DESCRIPTION  Adds a new checkbox to the dialog. The checkbox will be added to the button panel of
 *                the dialog and will be automatically positioned.
 *  $PARAM        text   Text to display next to the checkbox.
 *  $PARAM        width  Width of the checkbox in pixels.
 *  $PARAM        align  The alignment of the text.
 *  $RETURN       The button that has been added to the button panel of this dialog.
 *  $ENSURE       result != none
 *
 **************************************************************************************************/
function UWindowCheckbox addCheckbox(string text, optional int width, optional TextAlign align) {
	local float cx, cy, cw, ch;
	local UWindowCheckbox checkBox;

	if (width > 0.0) {
		cw = width;
	} else {
		cw = defaultCheckboxWidth;
	}
	ch = buttonHeight;
	cx = nextButtonPos - cw;
	cy = winHeight - buttonPanelHeight - buttonPanelBorderSize + (buttonPanelHeight - ch) / 2.0 - 3;

	checkBox = UWindowCheckbox(createControl(class'UWindowCheckbox', cx, cy, cw, ch));
  checkBox.setText(text);
  checkBox.align = align;
  checkBox.setFont(F_Bold);

	nextButtonPos -= cw + buttonSpace;

	return checkBox;
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/

defaultproperties
{
     wrapLength=85
     notifyInfo="You have to tick the checkbox below - otherwise this message will come up again."
     hasCloseButton=False
}
