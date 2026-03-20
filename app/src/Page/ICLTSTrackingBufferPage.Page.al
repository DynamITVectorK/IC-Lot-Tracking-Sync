/// <summary>
/// List page for monitoring the ICLTS Tracking Buffer.
/// Allows administrators to review pending and processed item-tracking transfer lines.
/// </summary>
page 50302 "ICLTS Tracking Buffer"
{
    Caption = 'ICLTS Tracking Buffer';
    PageType = List;
    SourceTable = "ICLTS Tracking Buffer";
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
                    ToolTip = 'Unique sequential entry number.';
                }
                field("IC Partner Code"; Rec."IC Partner Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'The IC partner the document was addressed to.';
                }
                field("Outbound Doc. No."; Rec."Outbound Doc. No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'The sales order number in the sending company.';
                }
                field("Outbound Line No."; Rec."Outbound Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'The sales line number that owns this tracking assignment.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'The item that carries the lot or serial tracking.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'The item variant code, if any.';
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'The lot number to be transferred.';
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'The serial number to be transferred, if applicable.';
                }
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                    ApplicationArea = All;
                    ToolTip = 'The quantity in the item''s base unit of measure.';
                }
                field("Processed"; Rec."Processed")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates whether this tracking line has been applied to the inbound purchase order.';
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Date and time when this buffer line was created.';
                }
                field("Processed At"; Rec."Processed At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Date and time when this buffer line was processed.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowPending)
            {
                Caption = 'Show Pending';
                Image = Filter;
                ApplicationArea = All;
                ToolTip = 'Filter the list to show only unprocessed tracking lines.';

                trigger OnAction()
                begin
                    Rec.SetRange("Processed", false);
                    CurrPage.Update(false);
                end;
            }
            action(ShowAll)
            {
                Caption = 'Show All';
                Image = RemoveFilterLines;
                ApplicationArea = All;
                ToolTip = 'Remove the processed filter and show all tracking lines.';

                trigger OnAction()
                begin
                    Rec.SetRange("Processed");
                    CurrPage.Update(false);
                end;
            }
            action(DeleteProcessed)
            {
                Caption = 'Delete Processed';
                Image = Delete;
                ApplicationArea = All;
                ToolTip = 'Delete processed tracking buffer lines older than the configured retention period.';

                trigger OnAction()
                var
                    ICLTSSetup: Record "ICLTS Setup";
                    ICLTSRepository: Codeunit "ICLTS Repository";
                    ICLTSSetupMgt: Codeunit "ICLTS Setup Mgt.";
                begin
                    ICLTSSetupMgt.GetSetup(ICLTSSetup);
                    ICLTSRepository.DeleteProcessedTrackingLines(ICLTSSetup."Log Retention Days");
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
