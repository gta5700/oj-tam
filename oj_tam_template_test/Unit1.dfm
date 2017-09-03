object Form4: TForm4
  Left = 0
  Top = 0
  Caption = 'Form4'
  ClientHeight = 422
  ClientWidth = 882
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 882
    Height = 308
    Align = alClient
    BevelOuter = bvNone
    Caption = '  '
    TabOrder = 0
    object Splitter1: TSplitter
      Left = 259
      Top = 0
      Width = 5
      Height = 308
    end
    object Splitter2: TSplitter
      Left = 618
      Top = 0
      Width = 5
      Height = 308
      Align = alRight
      ExplicitLeft = 259
    end
    object memoSrc: TMemo
      Left = 0
      Top = 0
      Width = 259
      Height = 308
      Align = alLeft
      Lines.Strings = (
        'Lorem ipsum <dolor> sit <<amet>>, '
        'consectetur adipisicing elit, sed do eiusmod '
        'tempor incididunt ut <labore> et dolore magna '
        'aliqua. Ut enim ad minim veniam, quis nostrud '
        'exercitation ullamco laboris nisi ut aliquip ex ea '
        'commodo consequat. Duis aute irure dolor in '
        'reprehenderit in voluptate velit esse cillum '
        'dolore eu fugiat nulla pariatur. <Excepteur> '
        'sint occaecat cupidatat non proident, sunt in '
        'culpa qui <officia> deserunt mollit anim id est '
        'laborum.')
      ScrollBars = ssVertical
      TabOrder = 0
    end
    object memoTag: TMemo
      Left = 264
      Top = 0
      Width = 354
      Height = 308
      Align = alClient
      ScrollBars = ssVertical
      TabOrder = 1
    end
    object memoDest: TMemo
      Left = 623
      Top = 0
      Width = 259
      Height = 308
      Align = alRight
      ScrollBars = ssVertical
      TabOrder = 2
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 308
    Width = 882
    Height = 114
    Align = alBottom
    BevelOuter = bvNone
    Caption = '  '
    TabOrder = 1
    object Label1: TLabel
      Left = 20
      Top = 69
      Width = 63
      Height = 13
      Caption = 'open Bracket'
    end
    object Label2: TLabel
      Left = 20
      Top = 88
      Width = 63
      Height = 13
      Caption = 'close Bracket'
    end
    object btnDetectTag: TButton
      Left = 8
      Top = 9
      Width = 75
      Height = 25
      Caption = 'Detect tag'
      TabOrder = 0
      OnClick = btnDetectTagClick
    end
    object chCaseSensitive: TCheckBox
      Left = 116
      Top = 17
      Width = 89
      Height = 17
      Caption = ' CaseSensitive'
      TabOrder = 1
    end
    object edCloseBracked: TEdit
      Left = 116
      Top = 88
      Width = 25
      Height = 21
      MaxLength = 1
      TabOrder = 2
      Text = '>'
    end
    object edOpenBracked: TEdit
      Left = 116
      Top = 61
      Width = 25
      Height = 21
      MaxLength = 1
      TabOrder = 3
      Text = '<'
    end
    object btnSubstituteUC: TButton
      Left = 417
      Top = 16
      Width = 128
      Height = 25
      Caption = 'Substitute /UPPER'
      TabOrder = 4
      OnClick = btnSubstitute_XXX_Click
    end
    object btnSubstituteLC: TButton
      Left = 273
      Top = 17
      Width = 128
      Height = 25
      Caption = 'Substitute /LOWER'
      TabOrder = 5
      OnClick = btnSubstitute_XXX_Click
    end
    object Button1: TButton
      Left = 273
      Top = 65
      Width = 128
      Height = 25
      Caption = 'ShowTags'
      TabOrder = 6
      OnClick = Button1Click
    end
  end
end
