#include<core.p4>
#if __TARGET_TOFINO__ == 2
#include<t2na.p4>
#else
#include<tna.p4>
#endif

// Total Memory = 500KB, Ratio = 0.2
// Filter Memory = 100KB
// Sketch Memory = 400KB


#define BUCKET_ARRAY_LEN 16384 //2^14
#define CM_ARRAY_LEN 32768 //2^15
#define THRESHOLD 4

/* header definitions */
header Ethernet {
	bit<48> dstAddr;
	bit<48> srcAddr;
	bit<16> etherType;
}

header Ipv4{
	bit<4> version;
	bit<4> ihl;
	bit<8> diffserv;
    bit<16> total_len;
	bit<16> identification;
	bit<3> flags;
	bit<13> fragOffset;
	bit<8> ttl;
    bit<8> protocol;
	bit<16> checksum;
	bit<32> srcAddr;
	bit<32> dstAddr;
}  

struct ingress_headers_t{
	Ethernet ethernet;
	Ipv4 ipv4;
}

struct ingress_metadata_t{
	int<8> time;
	bit<32> rnum1;
	bit<32> rnum2;
	bit<32> rnum3;
	int<8> count1;
	int<8> count2;
	int<8> count3;
	bit<4> counter1;
	bit<4> counter2;
	bit<4> counter3;
	bit<32> mix;
	// int<8> min;
}

struct egress_headers_t {}
struct egress_metadata_t {}

struct reg{
	int<8> window_idx;
  	int<8> cnt;
}

enum bit<16> ether_type_t {
    IPV4    = 0x0800,
    ARP     = 0x0806
}

enum bit<8> ip_proto_t {
    ICMP    = 1,
    IGMP    = 2,
    TCP     = 6,
    UDP     = 17
}

/* parser processing */
// @pa_atomic("ingress", "metadata.rng")
// @pa_atomic("ingress", "metadata.cond")
parser IngressParser(packet_in pkt,
	out ingress_headers_t hdr,
	out ingress_metadata_t metadata,
	out ingress_intrinsic_metadata_t ig_intr_md)
{
	state start{
		pkt.extract(ig_intr_md);
		pkt.advance(PORT_METADATA_SIZE);
		transition parse_ethernet;
	}

	state parse_ethernet{
		pkt.extract(hdr.ethernet);
        transition select((bit<16>)hdr.ethernet.etherType) {
            (bit<16>)ether_type_t.IPV4      : parse_ipv4;
            (bit<16>)ether_type_t.ARP       : accept;
            default : accept;
        }
	}

	state parse_ipv4{
		pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            (bit<8>)ip_proto_t.ICMP             : accept;
            (bit<8>)ip_proto_t.IGMP             : accept;
            (bit<8>)ip_proto_t.TCP              : accept;
            (bit<8>)ip_proto_t.UDP              : accept;
            default : accept;
        }
	}
}


/* ingress */
control Ingress(inout ingress_headers_t hdr,
		inout ingress_metadata_t meta,
		in ingress_intrinsic_metadata_t ig_intr_md,
		in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
		inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
		inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{	
	// stage 1

	// generate a random number and get leftmost index
	Register<bit<32>, _>(1) counter1;
	RegisterAction<bit<32>, _, bit<32>>(counter1) increment_counter1 = {
		void apply(inout bit<32> value, out bit<32> result) {
			value = value + 32w1;
			result = value;
		}
	};
	action generate_num1(){
		meta.rnum1 = increment_counter1.execute(0) ^ meta.mix;
	}
	action set_level1(int<8> level) {
		meta.count1 = level;
	}
	table cal_level1 {
		key = {
			meta.rnum1 : lpm;
		}
		actions = {
			set_level1;
		}
	}

	// calculate the bucket index
	CRCPolynomial<bit<32>>(coeff=0x04C11DB7,reversed=true, msb=false, extended=false, init=32w0xFFFFFFFF, xor=32w0xFFFFFFFF) crc32_1;
	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, crc32_1) hash1;
	Register<reg,bit<14>>(BUCKET_ARRAY_LEN) stage1;
	RegisterAction<reg,bit<14>,bit<4>>(stage1) stage1_alu={
		void apply(inout reg bucket, out bit<4> out_cnt){
			if (meta.time - bucket.window_idx >= 3) {
				bucket.window_idx = meta.time;
				bucket.cnt = meta.count1;
			}
			else {
				if (meta.count1 > bucket.cnt) {
					bucket.window_idx = meta.time;
					bucket.cnt = meta.count1;
				}
			}
			out_cnt = (bit<4>) (bucket.cnt [3:0]);
		}
	};
	action stage1_action(){
		meta.counter1 = stage1_alu.execute(hash1.get({hdr.ipv4.srcAddr})[13:0]);
	}

	// stage 2

	// generate a random number and get leftmost index
	Register<bit<32>, _>(1) counter2;
	RegisterAction<bit<32>, _, bit<32>>(counter2) increment_counter2 = {
		void apply(inout bit<32> value, out bit<32> result) {
			value = value + 32w2;
			result = value;
		}
	};
	action generate_num2(){
		meta.rnum2 = increment_counter2.execute(0) ^ meta.mix;
	}
	action set_level2(int<8> level) {
		meta.count2 = level;
	}
	table cal_level2 {
		key = {
			meta.rnum2 : lpm;
		}
		actions = {
			set_level2;
		}
	}

	// calculate the bucket index
    CRCPolynomial<bit<32>>(coeff=0x04C11DB7,reversed=true, msb=false, extended=false, init=32w0xFFFFFFFF, xor=32w0x00000000) crc32_2;
	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, crc32_2) hash2;
	Register<reg,bit<14>>(BUCKET_ARRAY_LEN) stage2;
	RegisterAction<reg,bit<14>,bit<4>>(stage2) stage2_alu={
		void apply(inout reg bucket, out bit<4> out_cnt){
			if (meta.time - bucket.window_idx >= 3) {
				bucket.window_idx = meta.time;
				bucket.cnt = meta.count2;
			}
			else{
				if (meta.count2 > bucket.cnt) {
				bucket.window_idx = meta.time;
				bucket.cnt = meta.count2;
				}				
			}
			out_cnt = (bit<4>) (bucket.cnt [3:0]);
		}
	};
	action stage2_action(){
		meta.counter2 = stage2_alu.execute(hash2.get({hdr.ipv4.srcAddr})[13:0]);
	}

	// stage 3

	// generate a random number and get leftmost index
	Register<bit<32>, _>(1) counter3;
	RegisterAction<bit<32>, _, bit<32>>(counter3) increment_counter3 = {
		void apply(inout bit<32> value, out bit<32> result) {
			value = value + 32w3;
			result = value;
		}
	};
	action generate_num3(){
		meta.rnum3 = increment_counter3.execute(0) ^ meta.mix;
	}
	action set_level3(int<8> level) {
		meta.count3 = level;
	}
	table cal_level3 {
		key = {
			meta.rnum3 : lpm;
		}
		actions = {
			set_level3;
		}
	}

	// calculate the bucket index
    CRCPolynomial<bit<32>>(coeff=0x04C11DB7,reversed=true, msb=false, extended=false, init=32w0xFFFFFFFF, xor=32w0x88888888) crc32_3;
	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, crc32_3) hash3;
	Register<reg,bit<14>>(BUCKET_ARRAY_LEN) stage3;
	RegisterAction<reg,bit<14>,bit<4>>(stage3) stage3_alu={
		void apply(inout reg bucket, out bit<4> out_cnt){
			if (meta.time - bucket.window_idx >= 3) {
				bucket.window_idx = meta.time;
				bucket.cnt = meta.count3;
			}
			else{
				if (meta.count3 > bucket.cnt) {
					bucket.window_idx = meta.time;
					bucket.cnt = meta.count3;
				}
			}
			out_cnt = (bit<4>) (bucket.cnt [3:0]);
		}
	};
	action stage3_action(){
		meta.counter3 = stage3_alu.execute(hash3.get({hdr.ipv4.srcAddr})[13:0]);
	}


	// CM layer 1
	// calculate the bucket index
    CRCPolynomial<bit<32>>(coeff=0x04C11DB7,reversed=true, msb=false, extended=false, init=32w0xFFFFFFFF, xor=32w0x12341234) crc32_4;
	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, crc32_4) hash4;
	Register<bit<32>,bit<16>>(CM_ARRAY_LEN) CM_1;
	RegisterAction<bit<32>,bit<16>,bit<32>>(CM_1) CM_1_alu={
		void apply(inout bit<32> bucket, out bit<32> result){
			bucket = bucket + 1;
			result = bucket;
		}
	};
	action CM_1_action(){
		CM_1_alu.execute(hash4.get({hdr.ipv4.srcAddr})[15:0]);
	}


	// CM layer 2
	// calculate the bucket index
    CRCPolynomial<bit<32>>(coeff=0x04C11DB7,reversed=true, msb=false, extended=false, init=32w0xFFFFFFFF, xor=32w0x43214321) crc32_5;
	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, crc32_5) hash5;
	Register<bit<32>,bit<16>>(CM_ARRAY_LEN) CM_2;
	RegisterAction<bit<32>,bit<16>,bit<32>>(CM_2) CM_2_alu={
		void apply(inout bit<32> bucket, out bit<32> result){
			bucket = bucket + 1;
			result = bucket;
		}
	};
	action CM_2_action(){
		CM_2_alu.execute(hash5.get({hdr.ipv4.srcAddr})[15:0]);
	}


	// CM layer 3
	// calculate the bucket index
    CRCPolynomial<bit<32>>(coeff=0x04C11DB7,reversed=true, msb=false, extended=false, init=32w0xFFFFFFFF, xor=32w0x56785678) crc32_6;
	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, crc32_6) hash6;
	Register<bit<32>,bit<16>>(CM_ARRAY_LEN) CM_3;
	RegisterAction<bit<32>,bit<16>,bit<32>>(CM_3) CM_3_alu={
		void apply(inout bit<32> bucket, out bit<32> result){
			bucket = bucket + 1;
			result = bucket;
		}
	};
	action CM_3_action(){
		CM_3_alu.execute(hash6.get({hdr.ipv4.srcAddr})[15:0]);
	}


	// add a counter to count the num of passing packets
	Register<int<32>, _>(1) counter_pass;
	RegisterAction<int<32>, _, int<32>>(counter_pass) increment_counter_pass = {
		void apply(inout int<32> value, out int<32> result) {
			value = value + 1;
			result = value;
		}
	};
	action counter_pass_act(){
		increment_counter_pass.execute(0);
	}



	/* ingress processing*/
	apply{
		meta.mix = (hdr.ipv4.srcAddr ^ hdr.ipv4.dstAddr);
		meta.time = (int<8>) ((ig_intr_md.ingress_mac_tstamp[41:10] & 0x00000030) >> 4) [7:0];
		
		// stage 1
		generate_num1();
		cal_level1.apply();
		meta.count1 = meta.count1 <= THRESHOLD ? meta.count1 : THRESHOLD;
		stage1_action();

		// stage 2
		generate_num2();
		cal_level2.apply();
		meta.count2 = meta.count2 <= THRESHOLD ? meta.count2 : THRESHOLD;
		stage2_action();

		// stage 3
		generate_num3();
		cal_level3.apply();
		meta.count3 = meta.count3 <= THRESHOLD ? meta.count3 : THRESHOLD;
		stage3_action();

		if (meta.counter1 >= THRESHOLD && meta.counter2 >= THRESHOLD && meta.counter3 >= THRESHOLD) {
			CM_1_action();
			CM_2_action();
			CM_3_action();
			counter_pass_act();
		}
	}
}

control IngressDeparser(packet_out pkt,
	inout ingress_headers_t hdr,
	in ingress_metadata_t meta,
	in ingress_intrinsic_metadata_for_deparser_t ig_dprtr_md)
{
	apply{
		pkt.emit(hdr);
	}
}


/* egress */
parser EgressParser(packet_in pkt,
	out egress_headers_t hdr,
	out egress_metadata_t meta,
	out egress_intrinsic_metadata_t eg_intr_md)
{
	state start{
		pkt.extract(eg_intr_md);
		transition accept;
	}
}

control Egress(inout egress_headers_t hdr,
	inout egress_metadata_t meta,
	in egress_intrinsic_metadata_t eg_intr_md,
	in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
	inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
	inout egress_intrinsic_metadata_for_output_port_t eg_oport_md)
{
	apply{}
}

control EgressDeparser(packet_out pkt,
	inout egress_headers_t hdr,
	in egress_metadata_t meta,
	in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)
{
	apply{
		pkt.emit(hdr);
	}
}


/* main */
Pipeline(IngressParser(),Ingress(),IngressDeparser(),
EgressParser(),Egress(),EgressDeparser()) pipe;

Switch(pipe) main;
