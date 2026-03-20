/// <summary>
/// Card page for managing the IC Lot Tracking Sync extension configuration.
/// Allows administrators to enable/disable individual modules and configure
/// the optional cross-tenant API endpoint.
/// </summary>
page 50300 "ICLTS Setup"
{
    Caption = 'IC Lot Tracking Sync Setup';
    PageType = Card;
    SourceTable = "ICLTS Setup";
    UsageCategory = Administration;
    ApplicationArea = All;
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("MOD-01 Enabled"; Rec."MOD-01 Enabled")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable the propagation of lot numbers and serial numbers in IC documents (MOD-01).';
                }
                field("MOD-02 Enabled"; Rec."MOD-02 Enabled")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable the propagation of item variant codes in IC documents (MOD-02).';
                }
                field("Log Retention Days"; Rec."Log Retention Days")
                {
                    ApplicationArea = All;
                    ToolTip = 'Number of days after which processed tracking buffer lines and gap log entries are automatically purged.';
                }
            }
            group(CrossTenantAPI)
            {
                Caption = 'Cross-Tenant API';

                field("API Base URL"; Rec."API Base URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Base URL of the partner tenant''s BC OData/API endpoint. Leave blank when both companies reside in the same tenant.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GapLog)
            {
                Caption = 'Gap Log';
                Image = Log;
                RunObject = page "ICLTS Gap Log Entries";
                ApplicationArea = All;
                ToolTip = 'Open the IC Lot Tracking Sync gap log to review errors and warnings.';
            }
            action(TrackingBuffer)
            {
                Caption = 'Tracking Buffer';
                Image = Intercompany;
                RunObject = page "ICLTS Tracking Buffer";
                ApplicationArea = All;
                ToolTip = 'Open the IC Lot Tracking Sync tracking buffer to monitor pending and processed item-tracking lines.';
            }
        }
    }

    trigger OnOpenPage()
    var
        ICLTSSetupMgt: Codeunit "ICLTS Setup Mgt.";
    begin
        ICLTSSetupMgt.GetSetup(Rec);
    end;
}
