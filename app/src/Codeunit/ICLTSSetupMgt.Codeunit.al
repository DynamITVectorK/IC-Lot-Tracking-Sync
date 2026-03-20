/// <summary>
/// Provides safe access to the singleton ICLTS Setup record.
/// All application-layer code must call this codeunit rather than accessing
/// the table directly.
/// </summary>
codeunit 50300 "ICLTS Setup Mgt."
{
    Access = Public;

    /// <summary>
    /// Returns true when the specified module is enabled for the current company.
    /// Initialises the setup record with defaults if it does not yet exist.
    /// </summary>
    /// <param name="ModuleCode">The module identifier to test.</param>
    /// <returns>True if the module is active; false if disabled or not yet configured.</returns>
    procedure IsModuleEnabled(ModuleCode: Enum "ICLTS Module Code"): Boolean
    var
        ICLTSSetup: Record "ICLTS Setup";
    begin
        ICLTSSetup.GetOrCreate(ICLTSSetup);
        exit(ICLTSSetup.IsModuleEnabled(ModuleCode));
    end;

    /// <summary>
    /// Returns the current company's ICLTS Setup record.
    /// Creates the record with defaults when it does not yet exist.
    /// </summary>
    /// <param name="ICLTSSetup">Output — the populated setup record.</param>
    procedure GetSetup(var ICLTSSetup: Record "ICLTS Setup")
    begin
        ICLTSSetup.GetOrCreate(ICLTSSetup);
    end;

    /// <summary>
    /// Saves changes to the ICLTS Setup record.
    /// Inserts a new record when none exists; modifies the existing record otherwise.
    /// </summary>
    /// <param name="ICLTSSetup">The record to persist.</param>
    procedure SaveSetup(var ICLTSSetup: Record "ICLTS Setup")
    begin
        if ICLTSSetup.Get() then
            ICLTSSetup.Modify(true)
        else
            ICLTSSetup.Insert(true);
    end;
}
