# Expiration-Filter

## Introduction

Mining recent heavy flows, which indicate the latest trends in high-speed networks, is vital to network management and numerous practical applications such as anomaly detection and congestion resolution. However, existing network traffic measurement solutions fall short of capturing and analyzing network traffic combined with temporal information, leaving us unaware of the real-time status of network streams, such as those undergoing congestion or attacks. This paper proposes the Expiration Filter (EF), which focuses on mining recent heavy flows, enhancing our understanding of the current behavioral patterns within the data. Given the skewness in real-world data streams, EF first filters out small flows to improve accuracy and tracks only flows with large volumes that have recently emerged. The EF also incorporates a dynamically self-cleaning mechanism to evict outdated records and free up memory space for new flows, thus fitting into the constrained on-chip space. Additionally, the adopted multi-stage design ensures the hardware implementation of EF in emerging programmable switches for line-rate processing. Hence, we provide detailed insights into implementing EF in programmable hardware under strict programming and resource constraints. Extensive experiments on real-world datasets demonstrate that our method outperforms the benchmarks in terms of flow size estimation and identifying top-_k_ recent flows.


## Descriptions

### Implementation:
The hardware and software versions of SwitchSketch are implemented on P4 and CPU platforms respectively.

### Dataset:
We use five datasets to evaluate the performance of our Expiration Filter in comparison with other methods:


- __CAIDA:__ The real Internet datasets CAIDA16 (https://catalog.caida.org/details/dataset/passive_2016_pcap) and CAIDA19 (https://catalog.caida.org/details/dataset/passive_2019_pcap) contain anonymized passive traffic traces collected from CAIDA’s passive monitors in 2016 and 2019 respectively. We treat every source IP address as the flow label. All 2.9 x 10<sup>7</sup> packets in one-minute CAIDA16 contain about 5.7 x 10<sup>5</sup> distinct flows, while the 3.5 x 10<sup>7</sup> packets in one-minute CAIDA19 contain about 3.6 x 10<sup>5</sup>distinct flows.

- __Webdocs:__ The Webdocs dataset was built from a series of web HTML documents (http://fimi.uantwerpen.be/data/), which includes 1 x 10<sup>6</sup> distinct flows and around 3.2 x 10<sup>7</sup> packets.

- __Synthetic Datasets:__ We generate two synthetic datasets that follow the Zipf distribution with skewness of 0.8 and 1.0 using the Numpy library of Python, noted as Zipf-0.8 and Zipf-1.0. The two datasets contain 5.2 x 10<sup>7</sup> packets and about 1.6 x 10<sup>6</sup> and 2.1 x 10<sup>6</sup> distinct flows, respectively.
