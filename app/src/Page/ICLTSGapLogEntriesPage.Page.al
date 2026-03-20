/// <summary>
/// List page for reviewing ICLTS Gap Log Entries.
/// Provides administrators with visibility into errors and warnings captured
/// by the IC Lot Tracking Sync event subscribers.
/// </summary>
page 50301 "ICLTS Gap Log Entries"
{
    Caption = 'ICLTS Gap Log Entries';
    PageType = List;
    SourceTable = "ICLTS Gap Log Entry";
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Unique sequential identifier for the log entry.';
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Date and time when the log entry was created.';
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = All;
                    StyleExpr = EntryTypeStyle;
                    ToolTip = 'Indicates whether this entry records a success, warning, or error.';
                }
                field("Module Code"; Rec."Module Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'The functional module that generated this log entry.';
                }
                field("Context"; Rec."Context")
                {
                    ApplicationArea = All;
                    ToolTip = 'Short description of the operation that was executing when this entry was created.';
                }
                field("Error Text"; Rec."Error Text")
                {
                    ApplicationArea = All;
                    ToolTip = 'Full error or informational message.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'The user who triggered the operation.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteOldEntries)
            {
                Caption = 'Delete Old Entries';
                Image = Delete;
                ApplicationArea = All;
                ToolTip = 'Delete gap log entries older than the configured retention period.';

                trigger OnAction()
                var
                    ICLTSSetup: Record "ICLTS Setup";
                    ICLTSRepository: Codeunit "ICLTS Repository";
                    ICLTSSetupMgt: Codeunit "ICLTS Setup Mgt.";
                begin
                    ICLTSSetupMgt.GetSetup(ICLTSSetup);
                    ICLTSRepository.DeleteOldGapLogEntries(ICLTSSetup."Log Retention Days");
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        EntryTypeStyle: Text;

    trigger OnAfterGetRecord()
    begin
        case Rec."Entry Type" of
            "ICLTS Log Entry Type"::Error:
                EntryTypeStyle := 'Unfavorable';
            "ICLTS Log Entry Type"::Warning:
                EntryTypeStyle := 'Ambiguous';
            else
                EntryTypeStyle := 'Favorable';
        end;
    end;
}
