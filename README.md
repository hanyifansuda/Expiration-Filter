# Expiration-Filter

## Introduction
Frequency estimation is to count how many times an item emerged in high-speed data streams, which is a fundamental task with numerous applications, including anomaly detection and network management. Although many advanced solutions have been proposed to provide accurate estimations, they did not take the time domain into account, thus unaware of recent data stream trends. Hence, this paper studies a new problem called \emph{recent frequency estimation} (RFE), which keeps tracking frequent items that emerged recently for better understanding the current behavioral patterns behind the data. Nevertheless, both the skewness in real-world data streams and the constrained high-speed storage space hinder accurate frequency estimation, not to mention the temporal information specified by RFE. Moreover, it is challenging to implement RFE in modern commodity ASICs due to strict programming and resource constraints. To this end, we propose Expiration Filter (EF) that incorporates a \emph{multi-stage structure} together with a dynamically \emph{self-cleaning mechanism} to gradually evict outdated items and reverse memory room for new ones. In addition, we detail how to implement EF in programmable switches. Extensive experiments on real-world datasets show that our method outperforms the benchmark in terms of frequency estimation and finding top-\emph{k} hot items.

## Descriptions

### Implementation:
The hardware and software versions of SwitchSketch are implemented on P4 and CPU platforms respectively.

### Dataset:
We use five datasets to evaluate the performance of our Expiration Filter in comparison with other methods:


- __(1) CAIDA:__ The real Internet datasets CAIDA16 \cite{caida2016} and CAIDA19 \cite{caida2019} contain anonymized passive traffic traces collected from CAIDA’s passive monitors in 2016 and 2019 respectively. We treat every source IP address as an item. All $2.9 \times 10^7$ items in one-minute CAIDA16 contain about $5.7 \times 10^5$ distinct items, while the $3.5 \times 10^7$ items in one-minute CAIDA19 contain about $3.6 \times 10^5$ distinct items.

- __(2) Webdocs:__ The Webdocs dataset was built from a series of web HTML documents \cite{webdoc}, which includes $1 \times 10^6$ distinct items in a total of around $3.2 \times 10^7$ items.

- __(3) Synthetic Datasets:__ We generate two synthetic datasets that follow the Zipf distribution \cite{powers1998applications} with skewness of 0.8 and 1.0 using the Numpy library of Python \cite{harris2020array}, noted as Zipf-0.8 and Zipf-1.0. The two datasets contain $5.2 \times 10^7$ items and about $1.6 \times 10^6$ and $2.1 \times 10^6$ distinct items, respectively.
