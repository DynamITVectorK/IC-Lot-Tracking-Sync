/// <summary>
/// Core engine responsible for capturing item-tracking data from outbound IC sales
/// documents and applying it to the inbound IC purchase documents.
/// </summary>
codeunit 50303 "ICLTS Tracking Engine"
{
    Access = Public;

    var
        ICLTSRepository: Codeunit "ICLTS Repository";
        ICLTSGapLogMgt: Codeunit "ICLTS Gap Log Mgt.";

    // ──────────────────────────────────────────────────────────────────────────
    // Outbound (capture)
    // ──────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// Reads all item-tracking reservation entries for the given sales order and
    /// writes one ICLTS Tracking Buffer line per lot/serial assignment.
    /// Should be called after a sales header has been added to the IC outbox.
    /// </summary>
    /// <param name="SalesHeader">The sales order whose tracking lines should be captured.</param>
    /// <param name="ICPartnerCode">The IC partner the document is addressed to.</param>
    procedure CaptureOutboundTracking(var SalesHeader: Record "Sales Header"; ICPartnerCode: Code[20])
    var
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        Context: Text[250];
    begin
        if ICPartnerCode = '' then
            exit;

        Context := CopyStr(
            StrSubstNo('CaptureOutboundTracking SalesOrder=%1 ICPartner=%2', SalesHeader."No.", ICPartnerCode),
            1, 250);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        if not SalesLine.FindSet() then
            exit;

        repeat
            ReservationEntry.SetRange("Source Type", Database::"Sales Line");
            ReservationEntry.SetRange("Source Subtype", SalesLine."Document Type".AsInteger());
            ReservationEntry.SetRange("Source ID", SalesLine."Document No.");
            ReservationEntry.SetRange("Source Ref. No.", SalesLine."Line No.");
            ReservationEntry.SetRange(Positive, false); // Sales = negative entries
            if ReservationEntry.FindSet() then
                repeat
                    if (ReservationEntry."Lot No." <> '') or (ReservationEntry."Serial No." <> '') then
                        // Quantities on Positive=false (sales) reservation entries are negative.
                        // ICLTSRepository.InsertTrackingBuffer applies Abs() so the buffer
                        // always stores positive quantities regardless of document direction.
                        ICLTSRepository.InsertTrackingBuffer(
                            ICPartnerCode,
                            SalesHeader."No.",
                            SalesLine."Line No.",
                            SalesLine."No.",
                            SalesLine."Variant Code",
                            ReservationEntry."Lot No.",
                            ReservationEntry."Serial No.",
                            ReservationEntry."Quantity (Base)",
                            CopyStr(ReservationEntry.Description, 1, 100));
                until ReservationEntry.Next() = 0;
        until SalesLine.Next() = 0;

        ICLTSGapLogMgt.LogSuccess("ICLTS Module Code"::"MOD-01", Context);
    end;

    // ──────────────────────────────────────────────────────────────────────────
    // Inbound (apply)
    // ──────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// Reads pending ICLTS Tracking Buffer lines for the given IC partner and outbound
    /// document number, then writes the corresponding item-tracking reservation entries
    /// on the newly created purchase order.
    /// </summary>
    /// <param name="PurchaseHeader">The purchase order that was just created from the IC inbox.</param>
    /// <param name="ICPartnerCode">The IC partner code of the sending company.</param>
    /// <param name="OutboundDocNo">The sales order number in the sending company (vendor order no.).</param>
    procedure ApplyInboundTracking(var PurchaseHeader: Record "Purchase Header"; ICPartnerCode: Code[20]; OutboundDocNo: Code[20])
    var
        TrackingBuffer: Record "ICLTS Tracking Buffer";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        NextEntryNo: Integer;
        Context: Text[250];
    begin
        if (ICPartnerCode = '') or (OutboundDocNo = '') then
            exit;

        Context := CopyStr(
            StrSubstNo('ApplyInboundTracking PurchOrder=%1 ICPartner=%2 OutboundDoc=%3',
                PurchaseHeader."No.", ICPartnerCode, OutboundDocNo),
            1, 250);

        ICLTSRepository.GetPendingTrackingLines(TrackingBuffer, ICPartnerCode, OutboundDocNo);
        if not TrackingBuffer.FindSet() then
            exit;

        // Lock before reading the last entry no. to prevent duplicate allocation
        // in concurrent scenarios (e.g. multiple job queue entries processing IC docs).
        NextEntryNo := GetNextReservationEntryNo();

        repeat
            // Match to the purchase line by item / variant
            PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
            PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
            PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
            PurchaseLine.SetRange("No.", TrackingBuffer."Item No.");
            PurchaseLine.SetRange("Variant Code", TrackingBuffer."Variant Code");
            if PurchaseLine.FindFirst() then begin
                // Write a surplus tracking entry for the purchase line.
                // "Surplus" status is correct here: the lot/serial is assigned to the
                // purchase line but the goods have not yet been received into inventory.
                // BC will update the status to "Tracking" or "Reservation" automatically
                // when the purchase order is further processed or received.
                ReservationEntry.Init();
                ReservationEntry."Entry No." := NextEntryNo;
                ReservationEntry.Positive := true;
                ReservationEntry."Item No." := TrackingBuffer."Item No.";
                ReservationEntry."Variant Code" := TrackingBuffer."Variant Code";
                ReservationEntry."Lot No." := TrackingBuffer."Lot No.";
                ReservationEntry."Serial No." := TrackingBuffer."Serial No.";
                ReservationEntry."Quantity (Base)" := TrackingBuffer."Quantity (Base)";
                ReservationEntry."Qty. to Handle (Base)" := TrackingBuffer."Quantity (Base)";
                ReservationEntry."Qty. to Invoice (Base)" := TrackingBuffer."Quantity (Base)";
                ReservationEntry."Source Type" := Database::"Purchase Line";
                ReservationEntry."Source Subtype" := PurchaseLine."Document Type".AsInteger();
                ReservationEntry."Source ID" := PurchaseLine."Document No.";
                ReservationEntry."Source Ref. No." := PurchaseLine."Line No.";
                ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Surplus;
                ReservationEntry.Description := CopyStr(TrackingBuffer.Description, 1, MaxStrLen(ReservationEntry.Description));
                ReservationEntry."Creation Date" := Today();
                // Record the user processing the inbound IC document on the receiving side.
                // The outbound capture timestamp / user is preserved in the tracking buffer record.
                ReservationEntry."Created By" := CopyStr(UserId(), 1, MaxStrLen(ReservationEntry."Created By"));
                ReservationEntry.Insert(false);

                NextEntryNo += 1;
            end else
                // Log a warning so administrators can identify lines where tracking
                // could not be applied due to a missing or mismatched purchase line.
                ICLTSGapLogMgt.LogWarning(
                    "ICLTS Module Code"::"MOD-01",
                    CopyStr(
                        StrSubstNo('ApplyInboundTracking: no purchase line found for Item=%1 Variant=%2 in PurchOrder=%3',
                            TrackingBuffer."Item No.", TrackingBuffer."Variant Code", PurchaseHeader."No."),
                        1, 250),
                    CopyStr(
                        StrSubstNo('Buffer EntryNo=%1 LotNo=%2 SerialNo=%3',
                            TrackingBuffer."Entry No.", TrackingBuffer."Lot No.", TrackingBuffer."Serial No."),
                        1, 2048));
        until TrackingBuffer.Next() = 0;

        ICLTSRepository.MarkTrackingLinesProcessed(ICPartnerCode, OutboundDocNo);
        ICLTSGapLogMgt.LogSuccess("ICLTS Module Code"::"MOD-01", Context);
    end;

    local procedure GetNextReservationEntryNo(): Integer
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        // Lock the table to serialise entry-number allocation across concurrent sessions.
        ReservationEntry.LockTable();
        if ReservationEntry.FindLast() then
            exit(ReservationEntry."Entry No." + 1);
        exit(1);
    end;
}
