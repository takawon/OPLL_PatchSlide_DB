; OPLL PatchSlide DB - standalone database installer.
; Build through installer/build-installer.ps1; payload is an explicit validated stage.
; The shared database itself is installed to {commonappdata}\OPLL_PatchSlide_DB by
; Manage-InstallerData.ps1 (InstallDb). {app} only holds the uninstall-time helper.
#ifndef SourceRoot
  #error SourceRoot must point to a validated distribution stage
#endif
#ifndef DbVersion
  #error DbVersion is required
#endif
#ifndef InstallerVersion
  #error InstallerVersion is required (numeric, e.g. 1.0.0.0)
#endif
[Setup]
AppId={{2506C8EC-CDB3-4205-8F6C-EDB91288DB5F}
AppName=OPLL PatchSlide DB
AppPublisher=Takawo.
VersionInfoCompany=Takawo.
AppVersion={#DbVersion}
VersionInfoVersion={#InstallerVersion}
VersionInfoProductVersion={#InstallerVersion}
DefaultDirName={autopf}\OPLL_PatchSlide_DB_Setup
DefaultGroupName=OPLL PatchSlide DB
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputBaseFilename=OPLL_PatchSlide_DB-{#DbVersion}-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
LicenseFile={#SourceRoot}\LICENSE
LanguageDetectionMethod=uilanguage
ShowLanguageDialog=yes
UsePreviousLanguage=yes
CloseApplications=no
RestartApplications=no
DisableProgramGroupPage=yes
[Languages]
Name: "english"; MessagesFile: "languages\Default.isl"
Name: "japanese"; MessagesFile: "languages\Japanese.isl"
[CustomMessages]
english.DatabaseTitle=Shared OPLL PatchSlide database
japanese.DatabaseTitle=OPLLパッチスライド共有DB
english.OperationFailed=Data operation failed. Exit code: %1
japanese.OperationFailed=データ処理に失敗しました。終了コード: %1
english.CloseDatabaseUsers=Close all applications using the PatchSlide database (including MGS Tone Craft and DAWs), then retry.
japanese.CloseDatabaseUsers=パッチスライドDBを使用するすべてのアプリ（MGS Tone Craft、DAWを含む）を終了して再試行してください。
english.MissingHelper=Uninstall helper is missing. Repair the installation before uninstalling.
japanese.MissingHelper=アンインストール用補助ファイルがありません。再インストールで修復してからアンインストールしてください。
english.DataRemovalTitle=OPLL PatchSlide DB - data removal
japanese.DataRemovalTitle=OPLL PatchSlide DB - データの削除
english.DataRemovalInfo=The shared database is used by multiple applications. It is deleted only if you select it below.
japanese.DataRemovalInfo=共有DBは複数のアプリが使用します。以下で選択した場合にのみ削除します。
english.SharedDatabasePath=Shared DB: %1
japanese.SharedDatabasePath=共有DB: %1
english.DeleteSharedDatabase=Delete shared PatchSlide DB (other applications may use it)
japanese.DeleteSharedDatabase=パッチスライド共有DBを削除する（他のアプリも使用する可能性があります）
english.Continue=Continue
japanese.Continue=続行
english.Cancel=Cancel
japanese.Cancel=キャンセル
english.ConfirmDeleteShared=Delete the three shared PatchSlide files? Other applications may stop finding their DB.
japanese.ConfirmDeleteShared=パッチスライド共有DBの3ファイルを削除しますか？ 他のアプリでもDBを利用できなくなる可能性があります。
english.HelperReparsePoint=Refusing a reparse point: %1
japanese.HelperReparsePoint=再解析ポイントのため処理を中止しました: %1
english.HelperFilesInUse=Close all applications using these files, then retry. %1
japanese.HelperFilesInUse=対象ファイルを使用しているすべてのアプリを終了してから再試行してください。%1
english.HelperSqliteSidecar=SQLite sidecar present: %1. Close all applications and complete/recover the database transaction before retrying.
japanese.HelperSqliteSidecar=SQLiteの付随ファイルが存在します: %1。すべてのアプリを終了し、データベースのトランザクションを完了または復旧してから再試行してください。
english.HelperSourceRequired=InstallDb requires -Source.
japanese.HelperSourceRequired=InstallDbには-Sourceの指定が必要です。
english.HelperPackagedHashMismatch=The packaged database hash is incorrect: %1
japanese.HelperPackagedHashMismatch=同梱データベースのハッシュが一致しません: %1
english.HelperDatabaseOperationPending=Another database operation or interrupted replacement exists. Inspect %1 and its backup before retrying; no database was changed.
japanese.HelperDatabaseOperationPending=別のデータベース操作が実行中、または前回の置換が中断されています。%1とそのバックアップを確認してから再試行してください。データベースは変更していません。
english.HelperStagedHashMismatch=Staged database verification failed: %1
japanese.HelperStagedHashMismatch=配置準備したデータベースの検証に失敗しました: %1
english.HelperRollbackFailed=Database replacement AND rollback failed. Close all applications. Preserve %1 and %2 for recovery. %3; rollback: %4
japanese.HelperRollbackFailed=データベースの置換と元の状態への復元の両方に失敗しました。すべてのアプリを終了してください。復旧のため%1と%2を保持してください。置換エラー: %3 / 復元エラー: %4
english.HelperReplacementRestored=Database replacement failed; the original files were restored. %1
japanese.HelperReplacementRestored=データベースの置換に失敗したため、元のファイルへ復元しました。%1
english.HelperDatabaseInstalled=The complete shared database set was installed and verified.
japanese.HelperDatabaseInstalled=共有データベース一式のインストールと検証が完了しました。
english.HelperDatabaseUninstallPending=A shared database replacement is active or interrupted. Resolve it before uninstalling database files.
japanese.HelperDatabaseUninstallPending=共有データベースの置換が実行中、または中断されています。置換の問題を解決してからデータベースファイルをアンインストールしてください。
english.HelperDatabaseRemoved=The three installer-managed shared database files were removed. Unknown files were preserved.
japanese.HelperDatabaseRemoved=インストーラーが管理する共有データベース3ファイルを削除しました。管理対象外のファイルは保持しました。
english.CannotWriteMessages=Cannot prepare the language messages file: %1
japanese.CannotWriteMessages=表示言語のメッセージファイルを準備できません: %1
english.DataOperationError=Data operation failed: %1
japanese.DataOperationError=データ処理に失敗しました: %1
[Files]
; Installed copy is used by the uninstaller. The same entry is also extracted
; to {tmp} by PrepareToInstall before {app} exists.
Source: "{#SourceRoot}\installer\Manage-InstallerData.ps1"; DestDir: "{app}"; Flags: ignoreversion
; dontcopy files never enter the uninstall log. DB ownership is explicitly conditional.
Source: "{#SourceRoot}\db\patchslide.sqlite"; Flags: dontcopy
Source: "{#SourceRoot}\db\patchslide_search.sqlite"; Flags: dontcopy
Source: "{#SourceRoot}\db\manifest.json"; Flags: dontcopy
[Code]
var
  RemoveShared: TNewCheckBox;
  DataHelper: String;

function Quote(const S: String): String;
begin
  Result := '"' + S + '"';
end;

procedure WriteHelperMessages(const Path: String);
var
  Messages: String;
begin
  Messages :=
    'HelperReparsePoint=' + CustomMessage('HelperReparsePoint') + #10 +
    'HelperFilesInUse=' + CustomMessage('HelperFilesInUse') + #10 +
    'HelperSqliteSidecar=' + CustomMessage('HelperSqliteSidecar') + #10 +
    'HelperSourceRequired=' + CustomMessage('HelperSourceRequired') + #10 +
    'HelperPackagedHashMismatch=' + CustomMessage('HelperPackagedHashMismatch') + #10 +
    'HelperDatabaseOperationPending=' + CustomMessage('HelperDatabaseOperationPending') + #10 +
    'HelperStagedHashMismatch=' + CustomMessage('HelperStagedHashMismatch') + #10 +
    'HelperRollbackFailed=' + CustomMessage('HelperRollbackFailed') + #10 +
    'HelperReplacementRestored=' + CustomMessage('HelperReplacementRestored') + #10 +
    'HelperDatabaseInstalled=' + CustomMessage('HelperDatabaseInstalled') + #10 +
    'HelperDatabaseUninstallPending=' + CustomMessage('HelperDatabaseUninstallPending') + #10 +
    'HelperDatabaseRemoved=' + CustomMessage('HelperDatabaseRemoved');
  if not SaveStringToFile(Path, UTF8Encode(Messages), False) then
    RaiseException(FmtMessage(CustomMessage('CannotWriteMessages'), [Path]));
end;

function RunData(const Mode, Source: String; var Detail: String): Boolean;
var
  Params, ResultPath, MessagesPath: String;
  ExitCode: Integer;
  Contents: AnsiString;
begin
  ResultPath := ExpandConstant('{tmp}\oplldb-data-result.txt');
  MessagesPath := ExpandConstant('{tmp}\oplldb-data-messages.txt');
  WriteHelperMessages(MessagesPath);
  DeleteFile(ResultPath);
  Params := '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File ' + Quote(DataHelper) +
    ' -Mode ' + Mode + ' -ResultFile ' + Quote(ResultPath) + ' -MessagesFile ' + Quote(MessagesPath);
  if Source <> '' then Params := Params + ' -Source ' + Quote(Source);
  Result := Exec(ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'), Params,
    '', SW_HIDE, ewWaitUntilTerminated, ExitCode);
  Detail := '';
  if LoadStringFromFile(ResultPath, Contents) then Detail := UTF8Decode(Contents);
  Result := Result and (ExitCode = 0);
  if (not Result) and (Detail = '') then Detail := FmtMessage(CustomMessage('OperationFailed'), [IntToStr(ExitCode)]);
  if (not Result) and (Detail <> '') then Detail := FmtMessage(CustomMessage('DataOperationError'), [Detail]);
  Log(Mode + ': ' + Detail);
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  Detail: String;
begin
  Result := '';
  ExtractTemporaryFile('patchslide.sqlite');
  ExtractTemporaryFile('patchslide_search.sqlite');
  ExtractTemporaryFile('manifest.json');
  // Use the staged helper before the application directory exists.
  ExtractTemporaryFile('Manage-InstallerData.ps1');
  DataHelper := ExpandConstant('{tmp}\Manage-InstallerData.ps1');
  if not RunData('InstallDb', ExpandConstant('{tmp}'), Detail) then
    Result := CustomMessage('CloseDatabaseUsers') + #13#10 + Detail;
end;

function InitializeUninstall: Boolean;
begin
  // Silent removal cannot express the shared-database deletion choice.
  Result := not UninstallSilent;
end;

procedure SelectAndRemoveData;
var
  Form: TSetupForm;
  Info: TNewStaticText;
  Accept, CancelButton: TNewButton;
  Detail: String;
begin
  DataHelper := ExpandConstant('{tmp}\Manage-InstallerData.ps1');
  if not FileCopy(ExpandConstant('{app}\Manage-InstallerData.ps1'), DataHelper, False) then
    RaiseException(CustomMessage('MissingHelper'));
  Form := CreateCustomForm(ScaleX(620), ScaleY(260), False, False);
  try
    Form.Caption := CustomMessage('DataRemovalTitle');
    Info := TNewStaticText.Create(Form);
    Info.Parent := Form;
    Info.SetBounds(ScaleX(16), ScaleY(16), ScaleX(586), ScaleY(70));
    Info.AutoSize := False;
    Info.WordWrap := True;
    Info.Caption := CustomMessage('DataRemovalInfo') + #13#10 +
      FmtMessage(CustomMessage('SharedDatabasePath'), [ExpandConstant('{commonappdata}\OPLL_PatchSlide_DB')]);
    RemoveShared := TNewCheckBox.Create(Form);
    RemoveShared.Parent := Form;
    RemoveShared.SetBounds(ScaleX(16), ScaleY(100), ScaleX(586), ScaleY(30));
    RemoveShared.Caption := CustomMessage('DeleteSharedDatabase');
    RemoveShared.Checked := True;
    Accept := TNewButton.Create(Form);
    Accept.Parent := Form;
    Accept.SetBounds(ScaleX(380), ScaleY(205), ScaleX(100), ScaleY(28));
    Accept.Caption := CustomMessage('Continue');
    Accept.Default := True;
    Accept.ModalResult := mrOk;
    CancelButton := TNewButton.Create(Form);
    CancelButton.Parent := Form;
    CancelButton.SetBounds(ScaleX(490), ScaleY(205), ScaleX(100), ScaleY(28));
    CancelButton.Caption := CustomMessage('Cancel');
    CancelButton.Cancel := True;
    CancelButton.ModalResult := mrCancel;
    if Form.ShowModal <> mrOk then Abort;
    if RemoveShared.Checked then begin
      if MsgBox(CustomMessage('ConfirmDeleteShared'),
        mbConfirmation, MB_YESNO or MB_DEFBUTTON2) <> IDYES then Abort;
      if not RunData('RemoveDb', '', Detail) then begin
        MsgBox(Detail, mbError, MB_OK);
        Abort;
      end;
    end;
  finally
    Form.Free;
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then SelectAndRemoveData;
end;
