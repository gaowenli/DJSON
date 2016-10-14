{***************************************************************************}
{                                                                           }
{           DJSON - (Delphi JSON library)                                    }
{                                                                           }
{           Copyright (C) 2016 Maurizio Del Magno                           }
{                                                                           }
{           mauriziodm@levantesw.it                                         }
{           mauriziodelmagno@gmail.com                                      }
{           https://github.com/mauriziodm/DSON.git                          }
{                                                                           }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Licensed under the Apache License, Version 2.0 (the "License");          }
{  you may not use this file except in compliance with the License.         }
{  You may obtain a copy of the License at                                  }
{                                                                           }
{      http://www.apache.org/licenses/LICENSE-2.0                           }
{                                                                           }
{  Unless required by applicable law or agreed to in writing, software      }
{  distributed under the License is distributed on an "AS IS" BASIS,        }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{  See the License for the specific language governing permissions and      }
{  limitations under the License.                                           }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  This project is based off of the ObjectsMappers unit included with the   }
{  Delphi MVC Framework project by Daniele Teti and the DMVCFramework Team. }
{                                                                           }
{***************************************************************************}



unit DJSON.Utils;

interface

uses
  System.Rtti, DJSON.Params, System.SysUtils;

type

  TdjUtils = class
  public
    class function IsPropertyToBeIgnored(const APropField: TRttiNamedObject; const AParams: IdjParams): Boolean; static;
    class function GetKeyName(const ARttiMember: TRttiNamedObject; const AParams:IdjParams): string; static;
    class function Bytes2String(const ABytes: TBytes): String;
    class procedure GetTypeNameIfEmpty(const APropField: TRttiNamedObject; const AParams:IdjParams; var ATypeName: String); static;
    class procedure GetItemsTypeNameIfEmpty(const APropField: TRttiNamedObject; const AParams:IdjParams; var AValueTypeName: String); overload; static;
    class procedure GetItemsTypeNameIfEmpty(const APropField: TRttiNamedObject; const AParams:IdjParams; var AKeyTypeName, AValueTypeName: String); overload; static;

    class function ISODateTimeToString(ADateTime: TDateTime): string;
    class function ISODateToString(ADate: TDateTime): string;
    class function ISOTimeToString(ATime: TTime): string;

    class function ISOStrToDateTime(DateTimeAsString: string): TDateTime;
    class function ISOStrToDate(DateAsString: string): TDate;
    class function ISOStrToTime(TimeAsString: string): TTime;
  end;

implementation

uses
  DJSON.Attributes, DJSON.Utils.RTTI, DJSON.Duck.PropField,
  System.DateUtils;

{ TdjUtils }

class procedure TdjUtils.GetItemsTypeNameIfEmpty(
  const APropField: TRttiNamedObject; const AParams: IdjParams;
  var AValueTypeName: String);
var
  LKeyTypeNameDummy: String;
begin
  LKeyTypeNameDummy := 'DummyKeyTypeName';
  GetItemsTypeNameIfEmpty(APropField, AParams, LKeyTypeNameDummy, AValueTypeName);
end;

class function TdjUtils.Bytes2String(const ABytes: TBytes): String;
var
  I: Integer;
  Sep: String;
begin
  Result := EmptyStr;
  Sep := EmptyStr;
  for I:=low(ABytes) to high(ABytes) do
  begin
    Result := Result + Sep + IntToHex(ABytes[I], 2);
    if I=0 then Sep := '-';
  end;
end;

class procedure TdjUtils.GetItemsTypeNameIfEmpty(
  const APropField: TRttiNamedObject; const AParams: IdjParams;
  var AKeyTypeName, AValueTypeName: String);
var
  LdsonItemsTypeAttribute: djItemsTypeAttribute;
begin
  // init
  LdsonItemsTypeAttribute := nil;
  // Only if needed
  if (not AKeyTypeName.IsEmpty) and (not AValueTypeName.IsEmpty) then
    Exit;
  // Get the attribute if exists (On the property or in the RttiType)
  if not TdjRTTI.HasAttribute<djItemsTypeAttribute>(APropField, LdsonItemsTypeAttribute) then
    TdjRTTI.HasAttribute<djItemsTypeAttribute>(TdjDuckPropField.RttiType(APropField), LdsonItemsTypeAttribute);
  // If the KeyType received as parameter is empty then get the type from
  //  the attribute and if also the attribute key type name is empty then
  //  get the default specified in the params
  if AKeyTypeName.IsEmpty then
  begin
    if Assigned(LdsonItemsTypeAttribute) and not LdsonItemsTypeAttribute.KeyQualifiedName.IsEmpty then
      AKeyTypeName := LdsonItemsTypeAttribute.KeyQualifiedName
    else
      AKeyTypeName := AParams.ItemsKeyDefaultQualifiedName;
  end;
  // If the ValueType received as parameter is empty then get the type from
  //  the attribute and if also the attribute value type name is empty then
  //  get the default specified in the params
  if AValueTypeName.IsEmpty then
  begin
    if Assigned(LdsonItemsTypeAttribute) and not LdsonItemsTypeAttribute.ValueQualifiedName.IsEmpty then
      AValueTypeName := LdsonItemsTypeAttribute.ValueQualifiedName
    else
      AValueTypeName := AParams.ItemsValueDefaultQualifiedName;
  end;
end;

class function TdjUtils.GetKeyName(const ARttiMember: TRttiNamedObject;
  const AParams:IdjParams): string;
var
  attrs: TArray<TCustomAttribute>;
  attr: TCustomAttribute;
  LdsonNameAttribute: djNameAttribute;
begin
  // If a dsonNameAttribute is present then use it else return the name
  //  of the property/field
  if TdjRTTI.HasAttribute<djNameAttribute>(ARttiMember, LdsonNameAttribute) then
    Result := LdsonNameAttribute.Name
  else
    Result := ARttiMember.Name;
  // If UpperCase or LowerCase names parama is specified...
  case AParams.NameCase of
    ncUpperCase: Result := UpperCase(ARttiMember.Name);
    ncLowerCase: Result := LowerCase(ARttiMember.Name);
  end;
end;

class procedure TdjUtils.GetTypeNameIfEmpty(
  const APropField: TRttiNamedObject; const AParams: IdjParams;
  var ATypeName: String);
var
  LdsonTypeAttribute: djTypeAttribute;
begin
  // init
  LdsonTypeAttribute := nil;
  // Only if needed
  if (not ATypeName.IsEmpty) then
    Exit;
  // Get the attribute if exists (On the property or in the RttiType)
  if not TdjRTTI.HasAttribute<djTypeAttribute>(APropField, LdsonTypeAttribute) then
    TdjRTTI.HasAttribute<djTypeAttribute>(TdjDuckPropField.RttiType(APropField), LdsonTypeAttribute);
  // If a dsonTypeAttritbute is found then retrieve the TypeName from it
  if Assigned(LdsonTypeAttribute) and not LdsonTypeAttribute.QualifiedName.IsEmpty then
    ATypeName := LdsonTypeAttribute.QualifiedName
end;

class function TdjUtils.ISODateTimeToString(ADateTime: TDateTime): string;
var
  fs: TFormatSettings;
begin
  fs.TimeSeparator := ':';
  Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', ADateTime, fs);
end;

class function TdjUtils.ISODateToString(ADate: TDateTime): string;
begin
  Result := FormatDateTime('YYYY-MM-DD', ADate);
end;

class function TdjUtils.ISOStrToDate(DateAsString: string): TDate;
begin
  Result := EncodeDate(StrToInt(Copy(DateAsString, 1, 4)), StrToInt(Copy(DateAsString, 6, 2)),
    StrToInt(Copy(DateAsString, 9, 2)));
  // , StrToInt
  // (Copy(DateAsString, 12, 2)), StrToInt(Copy(DateAsString, 15, 2)),
  // StrToInt(Copy(DateAsString, 18, 2)), 0);
end;

class function TdjUtils.ISOStrToDateTime(DateTimeAsString: string): TDateTime;
begin
  Result := EncodeDateTime(StrToInt(Copy(DateTimeAsString, 1, 4)),
    StrToInt(Copy(DateTimeAsString, 6, 2)), StrToInt(Copy(DateTimeAsString, 9, 2)),
    StrToInt(Copy(DateTimeAsString, 12, 2)), StrToInt(Copy(DateTimeAsString, 15, 2)),
    StrToInt(Copy(DateTimeAsString, 18, 2)), 0);
end;

class function TdjUtils.ISOStrToTime(TimeAsString: string): TTime;
begin
  Result := EncodeTime(StrToInt(Copy(TimeAsString, 1, 2)), StrToInt(Copy(TimeAsString, 4, 2)),
    StrToInt(Copy(TimeAsString, 7, 2)), 0);
end;

class function TdjUtils.ISOTimeToString(ATime: TTime): string;
var
  fs: TFormatSettings;
begin
  fs.TimeSeparator := ':';
  Result := FormatDateTime('hh:nn:ss', ATime, fs);
end;

class function TdjUtils.IsPropertyToBeIgnored(
  const APropField: TRttiNamedObject; const AParams: IdjParams): Boolean;
var
  LIgnoredProperty: String;
begin
  for LIgnoredProperty in AParams.IgnoredProperties do
    if SameText(APropField.Name, LIgnoredProperty) then
      Exit(True);
  Exit(False);
end;

end.
