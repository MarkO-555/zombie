	include "zombie.def"

	export  eth_init
	export	eth_in
	export	eth_out
	export  mac
	export  dmac
	export	type
	export	cmp_mac
	export	bmac
	
	.area	.data
dmac	rmb	6
mac	rmb	6
type	rmb 	2

	.area	.code

;;; fixme: mac should go in a well know place
;;;   for conjiguring into ROMS
bmac	.db	-1,-1,-1,-1,-1,-1
;;; keep this stuff together for easier copying to actual packet header,
;;; 	but all this stuff should go into RAM!!! (and out of area .code)
;;;     this means initing 'mac'.
mirror
	.db	-1,-1,-1,-1,-1,-1
	.db	0,1,2,3,4,5
	.dw	0x806
	
cmp_mac
	pshs	y,u	
	ldd	,u++
	cmpd	,y++
	bne	out@
	ldd	,u++
	cmpd	,y++
	bne	out@
	ldd	,u
	cmpd	,y
out@	puls	y,u,pc

	;; init this module
eth_init
	lbsr	arp_init
	leau	mirror,pcr
	leay	dmac,pcr
	ldb	#14
	lbra	memcpy

eth_in
	;; filter for mac or broadcast
	tfr	x,u
	leay	mac,pcr
	lbsr	cmp_mac
	beq	cont@
	leay	bmac,pcr
	lbsr	cmp_mac
	beq	cont@
	lbra	ip_drop
	;; drop
cont@	;; todo: find a raw eth connection here
	;; distribute to upper layers
	ldd	12,x
	leax	14,x
	cmpd	#$806		; is ARP?
	lbeq	arp_in
	cmpd	#$800		; is IPv4?
	lbeq	ip_in
	lbra	ip_drop
	

eth_out:
	lbsr	arp_resolve
	bcs	out@		; dont send if we sent an ARP request
	addd	#14		; add ethernet header length
	pshs	d
	leax	-14,x		; alloc eth header
	leay	,x
	leau	dmac,pcr
	ldb	#14
	lbsr	memcpy
	puls	d
	lbsr	dev_send	; send to device
out@	rts
