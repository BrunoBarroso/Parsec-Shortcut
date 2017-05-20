#include-once
#include <WindowsConstants.au3>
#include <GUIConstantsEx.au3>
#include <Memory.au3>
#include <GDIPlus.au3>
#include <WindowsConstants.au3>
Global $abErrors[5]
Func _GDIPlus_IncreasingBalls($iW, $iH, $iPerc, $sString = "Please wait...", $iRadius = 12, $iBalls = 5, $bHBitmap = True)
	Local Const $iDiameter = $iRadius * 2

	Local $tPointF1 = DllStructCreate("float;float")
	Local $pPointF1 = DllStructGetPtr($tPointF1)
	Local $tPointF2 = DllStructCreate("float;float")
	Local $pPointF2 = DllStructGetPtr($tPointF2)
	DllStructSetData($tPointF1, 1, $iDiameter)
	DllStructSetData($tPointF1, 2, 0)
	DllStructSetData($tPointF2, 1, $iDiameter)
	DllStructSetData($tPointF2, 2, $iDiameter)
	Local $hBrushBall2 = DllCall($__g_hGDIPDll, "uint", "GdipCreateLineBrush", "ptr", $pPointF1, "ptr", $pPointF2, "uint", 0xFF2287E7, "uint", 0xFF9BE6FE, "int", 1, "int*", 0)
	$hBrushBall2 = $hBrushBall2[6]
	$hBrushBall2Error = DllCall($__g_hGDIPDll, "uint", "GdipCreateLineBrush", "ptr", $pPointF1, "ptr", $pPointF2, "uint", 0xFFe78222, "uint", 0xFFFEB39B, "int", 1, "int*", 0)
	$hBrushBall2Error = $hBrushBall2Error[6]

	Local $hBitmap = _GDIPlus_BitmapCreateFromScan0($iW, $iH)

	Local Const $hCtxt = _GDIPlus_ImageGetGraphicsContext($hBitmap)
	_GDIPlus_GraphicsSetSmoothingMode($hCtxt, 2)
	_GDIPlus_GraphicsSetPixelOffsetMode($hCtxt, $GDIP_PIXELOFFSETMODE_HIGHQUALITY)

	Local Const $hBmp_BG = _GDIPlus_BitmapCreateFromMemory(_Background())
	Local $hBrushTexture = _GDIPlus_TextureCreate($hBmp_BG)
	_GDIPlus_BitmapDispose($hBmp_BG)
	_GDIPlus_GraphicsFillRect($hCtxt, 0, 0, $iW, $iH, $hBrushTexture)

	Local Const $hBrushBall1 = _GDIPlus_BrushCreateSolid(0xFF040404)

	Local Const $fFontSize = 11, $iSize = 10 * $iRadius + 2 * $iBalls * $iRadius
	Local $aPos[$iBalls + 2][4], $iArrayPos, $j = 1
	Local Static $aCircle[$iBalls + 1]
	For $i = 0 To $iBalls - 1
		$aPos[($iBalls - 1) - $i][0] = ($iW / 2) - (($iDiameter + $iRadius) * ($i + 1)) + (($iBalls - 1) / 2 * ($iDiameter + $iRadius)) + $iDiameter
		$aPos[($iBalls - 1) - $i][1] = ($iH - $iRadius) / 2
		_GDIPlus_GraphicsFillEllipse($hCtxt, $aPos[($iBalls - 1) - $i][0], $aPos[($iBalls - 1) - $i][1], $iDiameter, $iDiameter, $hBrushBall1) ;draw background
		$aPos[($iBalls - 1) - $i][2] = 100 / $iBalls
		$iArrayPos = Int($iPerc / ($aPos[($iBalls - 1) - $i][2]))
		$aPos[$iArrayPos][3] = ($iPerc - ($iArrayPos * ($aPos[($iBalls - 1) - $i][2]))) / $aPos[($iBalls - 1) - $i][2]
		If $iArrayPos > 0 Then
			For $j = 0 To $iArrayPos - 1
				$aPos[$j][3] = 1
			Next
		EndIf
	Next

	Local $fMax = 2, $hPen = _GDIPlus_PenCreate(0, 2)
	For $i = 0 To $iBalls - 1
		If Not $abErrors[$i] Then
			_GDIPlus_PenSetColor($hPen, 0x1000000 * Int(BitAND(BitShift(0xFF000000, 24), 0xFF) * ($fMax - $aCircle[$i])) + 0x2287E7)
			_GDIPlus_GraphicsFillEllipse($hCtxt, $iRadius + $aPos[$i][0] - $iRadius * $aPos[$i][3], $iRadius + $aPos[$i][1] - $iRadius * $aPos[$i][3], $iDiameter * $aPos[$i][3], $iDiameter * $aPos[$i][3], $hBrushBall2)
		Else
			_GDIPlus_PenSetColor($hPen, 0x1000000 * Int(BitAND(BitShift(0xFF000000, 24), 0xFF) * ($fMax - $aCircle[$i])) + 0xe78222)
			_GDIPlus_GraphicsFillEllipse($hCtxt, $iRadius + $aPos[$i][0] - $iRadius * $aPos[$i][3], $iRadius + $aPos[$i][1] - $iRadius * $aPos[$i][3], $iDiameter * $aPos[$i][3], $iDiameter * $aPos[$i][3], $hBrushBall2Error)
		EndIf
		If $aPos[$i][3] = 1 And $aCircle[$i] < $fMax Then ;draw balls according to percent
			_GDIPlus_GraphicsDrawEllipse($hCtxt, $iRadius + $aPos[$i][0] - $iRadius * (1 + $aCircle[$i]), $iRadius + $aPos[$i][1] - $iRadius * (1 + $aCircle[$i]), $iDiameter * (1 + $aCircle[$i]), $iDiameter * (1 + $aCircle[$i]), $hPen)
			$aCircle[$i] += 0.1
		EndIf
	Next

	If Not $iPerc Then
		For $i = 0 To $iBalls - 1
			$aCircle[$i] = 0
		Next
	EndIf

	Local Const $hFormat = _GDIPlus_StringFormatCreate()
	Local Const $hFamily = _GDIPlus_FontFamilyCreate("Arial")
	Local Const $hFont = _GDIPlus_FontCreate($hFamily, $fFontSize, 2)
	Local Const $hBrushTxt = _GDIPlus_BrushCreateSolid(0xFFFFFFFF)
	Local Const $tLayout = _GDIPlus_RectFCreate(0, 0, 0, 0)
	Local Const $aInfo = _GDIPlus_GraphicsMeasureString($hCtxt, $sString, $hFont, $tLayout, $hFormat)
	DllStructSetData($tLayout, "X", ($iW - DllStructGetData($aInfo[0], "Width")) / 2)
	DllStructSetData($tLayout, "Y", $iH - $iH / 4)
	_GDIPlus_GraphicsDrawStringEx($hCtxt, $sString, $hFont, $tLayout, $hFormat, $hBrushTxt)

	_GDIPlus_FontDispose($hFont)
	_GDIPlus_FontFamilyDispose($hFamily)
	_GDIPlus_StringFormatDispose($hFormat)
	_GDIPlus_BrushDispose($hBrushTxt)
	_GDIPlus_BrushDispose($hBrushTexture)

	_GDIPlus_GraphicsDispose($hCtxt)
	_GDIPlus_BrushDispose($hBrushBall1)
	_GDIPlus_BrushDispose($hBrushBall2)
	_GDIPlus_PenDispose($hPen)

	If $bHBitmap Then
		Local $hHBITMAP = _GDIPlus_BitmapCreateHBITMAPFromBitmap($hBitmap)
		_GDIPlus_BitmapDispose($hBitmap)
		Return $hHBITMAP
	EndIf
	Return $hBitmap
EndFunc   ;==>_GDIPlus_IncreasingBalls

Func Min($a, $b)
	If $a < $b Then Return $a
	Return $b
EndFunc   ;==>Min

;Code below was generated by: 'File to Base64 String' Code Generator v1.12 Build 2013-03-27

Func _Background($bSaveBinary = False, $sSavePath = @ScriptDir)
	Local $Background
	$Background &= 'iVBORw0KGgoAAAANSUhEUgAAAAQAAAAEAgMAAADUn3btAAAADFBMVEUaGhoTExMqKiofHx8rvcjDAAAAGUlEQVR4XgXAgRAAAAwCwNeY0+RyCqwTdX4IagG79dgjpgAAAABJRU5ErkJggg=='
	Local $bString = Binary(_Base64Decode($Background))
	If $bSaveBinary Then
		Local $hFile = FileOpen($sSavePath & "\stressed_linen.jpg", 18)
		FileWrite($hFile, $bString)
		FileClose($hFile)
	EndIf
	Return $bString
EndFunc   ;==>_Background

Func _Base64Decode($sB64String)
	Local $a_Call = DllCall("Crypt32.dll", "bool", "CryptStringToBinaryA", "str", $sB64String, "dword", 0, "dword", 1, "ptr", 0, "dword*", 0, "ptr", 0, "ptr", 0)
	If @error Or Not $a_Call[0] Then Return SetError(1, 0, "")
	Local $a = DllStructCreate("byte[" & $a_Call[5] & "]")
	$a_Call = DllCall("Crypt32.dll", "bool", "CryptStringToBinaryA", "str", $sB64String, "dword", 0, "dword", 1, "struct*", $a, "dword*", $a_Call[5], "ptr", 0, "ptr", 0)
	If @error Or Not $a_Call[0] Then Return SetError(2, 0, "")
	Return DllStructGetData($a, 1)
EndFunc   ;==>_Base64Decode