/// <summary>
/// Stores the per-company configuration for the IC Lot Tracking Sync extension.
/// One record per company; created automatically on first access.
/// </summary>
table 50300 "ICLTS Setup"
{
    Caption = 'ICLTS Setup';
    DataClassification = CustomerContent;
    DrillDownPageId = "ICLTS Setup";
    LookupPageId = "ICLTS Setup";

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(10; "MOD-01 Enabled"; Boolean)
        {
            Caption = 'Item Tracking Sync Enabled';
            DataClassification = CustomerContent;
        }
        field(11; "MOD-02 Enabled"; Boolean)
        {
            Caption = 'Variant Sync Enabled';
            DataClassification = CustomerContent;
        }
        field(20; "Log Retention Days"; Integer)
        {
            Caption = 'Log Retention (Days)';
            DataClassification = CustomerContent;
            InitValue = 30;
            MinValue = 1;
        }
        field(30; "API Base URL"; Text[250])
        {
            Caption = 'API Base URL';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Returns true when the specified functional module is enabled in this company's setup.
    /// </summary>
    /// <param name="ModuleCode">The module to test, e.g. "MOD-01".</param>
    /// <returns>True if the module is enabled; false otherwise.</returns>
    procedure IsModuleEnabled(ModuleCode: Enum "ICLTS Module Code"): Boolean
    begin
        if not Get() then
            exit(false);

        case ModuleCode of
            "ICLTS Module Code"::"MOD-01":
                exit("MOD-01 Enabled");
            "ICLTS Module Code"::"MOD-02":
                exit("MOD-02 Enabled");
            else
                exit(false);
        end;
    end;

    /// <summary>
    /// Returns or creates the singleton setup record for the current company.
    /// </summary>
    /// <param name="ICLTSSetup">Output — the setup record.</param>
    procedure GetOrCreate(var ICLTSSetup: Record "ICLTS Setup")
    begin
        if not ICLTSSetup.Get() then begin
            ICLTSSetup.Init();
            ICLTSSetup."Log Retention Days" := 30;
            ICLTSSetup.Insert(true);
        end;
    end;
}
