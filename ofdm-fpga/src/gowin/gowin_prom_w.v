//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//Tool Version: V1.9.9.03 Education
//Part Number: GW1NR-LV9QN88PC6/I5
//Device: GW1NR-9
//Device Version: C
//Created Time: Fri Dec 20 09:22:35 2024

// addr depth: 1024+1=1025
// data width: 16
// sin tableは1024+1個なので、1024個はSRAMに持って、残りの1つは組み合わせ回路で実現している
module Gowin_pROM (dout, clk, oce, ce, reset, ad);

output [15:0] dout;
input clk;
input oce;
input ce;
input reset;
input [10:0] ad;

wire [15:0] prom_inst_0_dout_w;
wire gw_gnd;
wire [15:0] _dout;

assign gw_gnd = 1'b0;
assign dout = ad[10] ? 16'h7fff : _dout;

pROM prom_inst_0 (
    .DO({prom_inst_0_dout_w[15:0],_dout[15:0]}),
    .CLK(clk),
    .OCE(oce),
    .CE(ce),
    .RESET(reset),
    .AD({ad[9:0],gw_gnd,gw_gnd,gw_gnd,gw_gnd})
);

defparam prom_inst_0.READ_MODE = 1'b0;
defparam prom_inst_0.BIT_WIDTH = 16;
defparam prom_inst_0.RESET_MODE = "SYNC";
defparam prom_inst_0.INIT_RAM_00 = 256'h02f202c0028d025b022901f701c401920160012e00fb00c90097006500320000;
defparam prom_inst_0.INIT_RAM_01 = 256'h061605e305b1057f054d051b04e804b604840452041f03ed03bb038903560324;
defparam prom_inst_0.INIT_RAM_02 = 256'h0938090608d408a20870083e080c07d907a707750743071106de06ac067a0648;
defparam prom_inst_0.INIT_RAM_03 = 256'h0c5a0c280bf60bc40b920b600b2d0afb0ac90a970a650a330a0109cf099d096b;
defparam prom_inst_0.INIT_RAM_04 = 256'h0f790f470f150ee40eb20e800e4e0e1c0dea0db80d860d540d220cf00cbe0c8c;
defparam prom_inst_0.INIT_RAM_05 = 256'h129612651233120111cf119e116c113a110810d610a410731041100f0fdd0fab;
defparam prom_inst_0.INIT_RAM_06 = 256'h15b1157f154d151c14ea14b914871455142413f213c1138f135d132b12fa12c8;
defparam prom_inst_0.INIT_RAM_07 = 256'h18c7189618651833180217d1179f176e173c170b16da16a816771645161415e2;
defparam prom_inst_0.INIT_RAM_08 = 256'h1bda1ba91b781b471b161ae51ab41a831a511a2019ef19be198d195b192a18f9;
defparam prom_inst_0.INIT_RAM_09 = 256'h1ee91eb81e881e571e261df51dc41d931d621d311d011cd01c9f1c6e1c3d1c0c;
defparam prom_inst_0.INIT_RAM_0a = 256'h21f321c3219221622131210120d0209f206f203e200e1fdd1fac1f7b1f4b1f1a;
defparam prom_inst_0.INIT_RAM_0b = 256'h24f824c8249824672437240723d723a723762346231622e522b5228422542224;
defparam prom_inst_0.INIT_RAM_0c = 256'h27f727c7279727682738270826d826a826782648261825e825b8258825582528;
defparam prom_inst_0.INIT_RAM_0d = 256'h2af02ac12a912a622a322a0329d329a429742945291528e528b6288628562827;
defparam prom_inst_0.INIT_RAM_0e = 256'h2de22db32d842d552d262cf72cc82c992c6a2c3b2c0c2bdc2bad2b7e2b4f2b1f;
defparam prom_inst_0.INIT_RAM_0f = 256'h30cd309f3070304230132fe52fb62f872f592f2a2efb2ecc2e9e2e6f2e402e11;
defparam prom_inst_0.INIT_RAM_10 = 256'h33b133833355332732f932cb329d326e3240321231e431b531873159312a30fc;
defparam prom_inst_0.INIT_RAM_11 = 256'h368d365f3632360435d735a9357b354e352034f234c434973469343b340d33df;
defparam prom_inst_0.INIT_RAM_12 = 256'h39603933390638d938ac387f3852382537f737ca379d37703742371536e836ba;
defparam prom_inst_0.INIT_RAM_13 = 256'h3c2a3bfe3bd23ba53b793b4c3b203af33ac63a9a3a6d3a403a1339e739ba398d;
defparam prom_inst_0.INIT_RAM_14 = 256'h3eec3ec03e943e683e3c3e103de43db83d8c3d603d343d083cdc3caf3c833c57;
defparam prom_inst_0.INIT_RAM_15 = 256'h41a34178414d412140f640cb409f40744048401d3ff13fc63f9a3f6f3f433f17;
defparam prom_inst_0.INIT_RAM_16 = 256'h4450442643fb43d143a6437b4351432642fb42d042a5427a424f422441f941ce;
defparam prom_inst_0.INIT_RAM_17 = 256'h46f346c9469f4675464b462145f745cd45a34579454f452444fa44d044a5447b;
defparam prom_inst_0.INIT_RAM_18 = 256'h498b49624939490f48e648bd4893486a4840481747ed47c4479a47704747471d;
defparam prom_inst_0.INIT_RAM_19 = 256'h4c174bef4bc74b9e4b754b4d4b244afb4ad34aaa4a814a584a2f4a0649dd49b4;
defparam prom_inst_0.INIT_RAM_1a = 256'h4e984e714e494e214df94dd14da94d814d594d314d094ce14cb94c914c684c40;
defparam prom_inst_0.INIT_RAM_1b = 256'h510d50e650bf50985071504a50234ffb4fd44fad4f854f5e4f374f0f4ee84ec0;
defparam prom_inst_0.INIT_RAM_1c = 256'h5375534f5329530352dc52b6529052695243521c51f551cf51a85181515b5134;
defparam prom_inst_0.INIT_RAM_1d = 256'h55d055ab55865560553b551554f054ca54a4547f54595433540d53e753c1539b;
defparam prom_inst_0.INIT_RAM_1e = 256'h581e57fa57d557b1578c57675743571e56f956d456af568a56655640561b55f6;
defparam prom_inst_0.INIT_RAM_1f = 256'h5a5f5a3b5a1859f459d059ac598859645940591c58f858d458b0588c58675843;
defparam prom_inst_0.INIT_RAM_20 = 256'h5c915c6f5c4c5c295c065be35bc05b9d5b7a5b575b345b105aed5ac95aa65a82;
defparam prom_inst_0.INIT_RAM_21 = 256'h5eb65e945e725e505e2e5e0c5dea5dc85da55d835d615d3e5d1c5cf95cd75cb4;
defparam prom_inst_0.INIT_RAM_22 = 256'h60cb60aa608960686047602660055fe45fc25fa15f805f5e5f3c5f1b5ef95ed7;
defparam prom_inst_0.INIT_RAM_23 = 256'h62d262b26292627262526232621161f161d161b06190616f614e612e610d60ec;
defparam prom_inst_0.INIT_RAM_24 = 256'h64ca64ab648b646c644d642e640f63ef63d063b06391637163516332631262f2;
defparam prom_inst_0.INIT_RAM_25 = 256'h66b26693667566576639661b65fc65de65c065a16582656465456526650764e9;
defparam prom_inst_0.INIT_RAM_26 = 256'h688a686d68506832681567f867da67bd67a06782676467476729670b66ed66d0;
defparam prom_inst_0.INIT_RAM_27 = 256'h6a526a366a1a69fd69e169c569a9698c697069536937691a68fd68e068c468a7;
defparam prom_inst_0.INIT_RAM_28 = 256'h6c096bee6bd36bb86b9d6b826b666b4b6b306b146af86add6ac16aa56a896a6e;
defparam prom_inst_0.INIT_RAM_29 = 256'h6db06d966d7c6d626d486d2e6d146cf96cdf6cc46caa6c8f6c756c5a6c3f6c24;
defparam prom_inst_0.INIT_RAM_2a = 256'h6f466f2d6f146efb6ee26ec96eb06e976e7d6e646e4a6e316e176dfe6de46dca;
defparam prom_inst_0.INIT_RAM_2b = 256'h70cb70b3709b7083706b7053703b7023700b6ff26fda6fc26fa96f906f786f5f;
defparam prom_inst_0.INIT_RAM_2c = 256'h723f7228721171fa71e371cc71b5719e7187717071587141712a711270fa70e3;
defparam prom_inst_0.INIT_RAM_2d = 256'h73a0738b7375735f734a7334731e730872f272dc72c572af72997282726c7255;
defparam prom_inst_0.INIT_RAM_2e = 256'h74f074dc74c774b3749e748974757460744b74367421740b73f673e173cb73b6;
defparam prom_inst_0.INIT_RAM_2f = 256'h762e761b760875f475e175cd75b975a67592757e756a75567542752d75197505;
defparam prom_inst_0.INIT_RAM_30 = 256'h775a774877367723771176fe76ec76d976c776b476a1768e767b766876557642;
defparam prom_inst_0.INIT_RAM_31 = 256'h7874786378517840782f781e780c77fb77e977d877c677b477a27790777e776c;
defparam prom_inst_0.INIT_RAM_32 = 256'h797a796a795b794a793a792a791a790a78f978e978d878c878b778a678957885;
defparam prom_inst_0.INIT_RAM_33 = 256'h7a6e7a607a517a427a337a247a157a0679f779e779d879c979b979aa799a798a;
defparam prom_inst_0.INIT_RAM_34 = 256'h7b507b427b347b277b197b0b7afd7aef7ae17ad37ac57ab77aa87a9a7a8c7a7d;
defparam prom_inst_0.INIT_RAM_35 = 256'h7c1e7c117c057bf97bec7bdf7bd37bc67bb97bac7b9f7b927b857b787b6a7b5d;
defparam prom_inst_0.INIT_RAM_36 = 256'h7cd97cce7cc27cb77cac7ca07c957c897c7e7c727c667c5a7c4e7c427c367c2a;
defparam prom_inst_0.INIT_RAM_37 = 256'h7d817d777d6d7d637d587d4e7d447d3a7d2f7d257d1a7d0f7d057cfa7cef7ce4;
defparam prom_inst_0.INIT_RAM_38 = 256'h7e157e0c7e037dfb7df27de97de07dd67dcd7dc47dba7db17da77d9e7d947d8a;
defparam prom_inst_0.INIT_RAM_39 = 256'h7e967e8e7e877e7f7e787e707e687e607e587e507e487e3f7e377e2f7e267e1e;
defparam prom_inst_0.INIT_RAM_3a = 256'h7f037efd7ef77ef07eea7ee37edd7ed67ecf7ec87ec17eba7eb37eac7ea57e9d;
defparam prom_inst_0.INIT_RAM_3b = 256'h7f5d7f587f537f4e7f497f437f3e7f387f337f2d7f277f227f1c7f167f107f0a;
defparam prom_inst_0.INIT_RAM_3c = 256'h7fa37fa07f9c7f987f947f907f8b7f877f837f7e7f7a7f757f717f6c7f677f62;
defparam prom_inst_0.INIT_RAM_3d = 256'h7fd67fd37fd17fce7fcb7fc87fc57fc27fbf7fbc7fb97fb57fb27fae7fab7fa7;
defparam prom_inst_0.INIT_RAM_3e = 256'h7ff57ff47ff27ff17fef7fed7fec7fea7fe87fe67fe47fe27fe07fdd7fdb7fd9;
defparam prom_inst_0.INIT_RAM_3f = 256'h7fff7fff7fff7fff7fff7fff7ffe7ffe7ffd7ffc7ffb7ffa7ff97ff87ff77ff6;

endmodule //Gowin_pROM
