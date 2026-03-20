/// <summary>
/// Provides helper procedures for writing to the ICLTS Gap Log Entry table.
/// All exception-handling code in the extension should use this codeunit
/// to record errors without propagating them to the standard BC call stack.
/// </summary>
codeunit 50302 "ICLTS Gap Log Mgt."
{
    Access = Public;

    var
        ICLTSRepository: Codeunit "ICLTS Repository";

    /// <summary>
    /// Logs an error that was caught inside an event subscriber or engine procedure.
    /// This procedure is intentionally designed to be called from inside a catch block
    /// so it must never throw an exception itself.
    /// </summary>
    /// <param name="ModuleCode">The module where the error originated.</param>
    /// <param name="Context">A short, human-readable description of the failing operation.</param>
    /// <param name="ErrorText">The full error message or exception text.</param>
    procedure LogError(ModuleCode: Enum "ICLTS Module Code"; Context: Text[250]; ErrorText: Text[2048])
    begin
        SafeInsert("ICLTS Log Entry Type"::Error, ModuleCode, Context, ErrorText);
    end;

    /// <summary>
    /// Logs a warning raised during normal processing that did not abort the operation.
    /// </summary>
    /// <param name="ModuleCode">The module where the warning originated.</param>
    /// <param name="Context">A short, human-readable description of the operation.</param>
    /// <param name="WarningText">The warning message text.</param>
    procedure LogWarning(ModuleCode: Enum "ICLTS Module Code"; Context: Text[250]; WarningText: Text[2048])
    begin
        SafeInsert("ICLTS Log Entry Type"::Warning, ModuleCode, Context, WarningText);
    end;

    /// <summary>
    /// Logs a successful completion of an operation for audit purposes.
    /// </summary>
    /// <param name="ModuleCode">The module that completed successfully.</param>
    /// <param name="Context">A short, human-readable description of the completed operation.</param>
    procedure LogSuccess(ModuleCode: Enum "ICLTS Module Code"; Context: Text[250])
    begin
        SafeInsert("ICLTS Log Entry Type"::Success, ModuleCode, Context, '');
    end;

    local procedure SafeInsert(
        EntryType: Enum "ICLTS Log Entry Type";
        ModuleCode: Enum "ICLTS Module Code";
        Context: Text[250];
        ErrorText: Text[2048])
    begin
        // Silently absorb any database error so the logger can never crash the call stack.
        if not TryInsertLogEntry(EntryType, ModuleCode, Context, ErrorText) then;
    end;

    [TryFunction]
    local procedure TryInsertLogEntry(
        EntryType: Enum "ICLTS Log Entry Type";
        ModuleCode: Enum "ICLTS Module Code";
        Context: Text[250];
        ErrorText: Text[2048])
    begin
        ICLTSRepository.InsertGapLogEntry(EntryType, ModuleCode, Context, ErrorText);
    end;
}
