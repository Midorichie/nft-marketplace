(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))

;; NFT Asset Representation
(define-non-fungible-token bitcoin-backed-nft (string-ascii 256))

;; Store for tracking Bitcoin-backed NFT metadata
(define-map nft-metadata 
  { token-id: (string-ascii 256) }
  {
    owner: principal,
    bitcoin-tx-ref: (string-ascii 256),
    fractional-shares: uint,
    royalty-rate: uint
  }
)

;; Mint Bitcoin-backed NFT
(define-public (mint-nft 
  (token-id (string-ascii 256))
  (bitcoin-tx-ref (string-ascii 256))
  (fractional-shares uint)
  (royalty-rate uint)
)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (try! (nft-mint? bitcoin-backed-nft token-id tx-sender))
    (map-set nft-metadata 
      { token-id: token-id }
      {
        owner: tx-sender,
        bitcoin-tx-ref: bitcoin-tx-ref,
        fractional-shares: fractional-shares,
        royalty-rate: royalty-rate
      }
    )
    (ok true)
  )
)

;; Transfer NFT with Royalty Calculation
(define-public (transfer-nft 
  (token-id (string-ascii 256))
  (new-owner principal)
)
  (let 
    (
      (current-metadata (unwrap! (map-get? nft-metadata { token-id: token-id }) ERR-NOT-AUTHORIZED))
      (current-owner (get owner current-metadata))
      (royalty-rate (get royalty-rate current-metadata))
    )
    (asserts! (is-eq tx-sender current-owner) ERR-NOT-AUTHORIZED)
    (try! (nft-transfer? bitcoin-backed-nft token-id current-owner new-owner))
    (map-set nft-metadata 
      { token-id: token-id }
      (merge current-metadata { owner: new-owner })
    )
    (ok true)
  )
)
