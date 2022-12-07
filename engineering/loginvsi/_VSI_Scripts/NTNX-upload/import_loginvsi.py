#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2018 Nutanix Inc.  All rights reserved.
#
# Aurthor: William.Davidson@nutanix.com
#

"""
Proof of Concept reading in configuration and results data for LoginVSI tests
and posting to Ray API for Performance Results storage and analysis.

Example usage:

python3 import_loginvsi.py \
    -c config.json \
    -r 0bafb33-3f3c_AOS5.10.1_AHV20170830.185_Win2K19_7vms_8vCPU_32GB_180Users_S-M_ICA.csv \
    -b 0bafb33-3f3c_AOS5.10.1_AHV20170830.185_Win2K19_7vms_8vCPU_32GB_180Users_S-M_ICA-boottime.csv \
    -a "http://ray.buster.nutanix.com:8080/api" \
    -t e33e36af7568d7b994408bbc8e9600a6546c7f75
"""

import argparse
import json
import logging
import pandas as pd
import requests


class ImportLoginVSI(object):
    def __init__(self, args):
        self.api_url = args.api
        self.api_token = args.token
        self.config_file = args.config
        self.results_file = args.results
        self.boottime_file = args.boottime
        self.config = None
        self.results = None
        self.cluster = None

    def api(self, action='get', url=None, data=None, json=None):
        """
        Forms API connections
        """
        try:
            url = '{}/{}'.format(self.api_url, url)
            headers = {'Authorization': 'Token {}'.format(self.api_token)}
            response = getattr(requests, action)(url, data=data, headers=headers, json=json)
            logging.debug(url, response.status_code, response.text)
        except requests.exceptions.ConnectionError as e:
            logging.exception('Connection failed: {}'.format(e))
            raise
        return response

    def start(self):
        """
        Start reading configs and posting new results
        """

        # Open Config
        try:
            with open(self.config_file, encoding='utf-8') as f:
                self.config = json.load(f)
                if not self.config:
                    logging.critical('Config file {} was empty.'.format(self.config_file))
                    return
                logging.info('Opened config file {}.'.format(self.config_file))
        except FileNotFoundError:
            logging.critical('Config file {} does not exist.'.format(self.config_file))
            return

        # Open Results CSV
        try:
            runs = pd.read_csv(self.results_file, parse_dates=['DataTime', 'VSIMaxReached'])
            if runs.empty:
                logging.critical('Results file {} is empty.'.format(self.results_file))
                return
            logging.info('Opened results file {}.'.format(self.results_file))
        except FileNotFoundError:
            logging.critical('Results file {} does not exist.'.format(self.results_file))
            return

        # Open Boottime CSV
        boottime = pd.DataFrame({
            'Boottime': [],
            'TotalDesktops': [],
        })
        try:
            boottime = pd.read_csv(self.boottime_file, parse_dates=['DataTime'])
            if boottime.empty:
                logging.warning('Boottime file {} is empty.'.format(self.boottime_file))
            else:
                logging.info('Opened Boottime file {}.'.format(self.boottime_file))
        except FileNotFoundError:
            logging.warning('Boottime file {} does not exist.'.format(self.boottime_file))

        # Get values from Config
        self.cluster = {
            'cluster_name': self.config['ClusterName'],
            'node_cnt': self.config['NodeCount'],
            'cpu_model': self.config['CPUType'],
            'phy_core_cnt': self.config['CPUCores'],
            'cpu_thread_cnt': self.config['CPUThreadCount'],
            'phy_socket_cnt': self.config['CPUSocketCount'],
            'cpu_speed_ghz': self.config['CPUSpeed'],
            'mem_gb': self.config['MemoryGB'],
            'ssd_cnt': self.config['SSDCount'],
        }

        # Check to see if the Cluster exists
        cluster_url = 'cluster/?cluster_name={}&node_cnt={}'.format(
            self.cluster['cluster_name'],
            self.cluster['node_cnt'],
        )
        cluster = self.api('get', cluster_url)
        if cluster.status_code != 200:
            logging.critical('Cluster API could not be contacted.')
            return

        # Get the cluster or create a new cluster
        cluster = cluster.json()
        if cluster['count'] == 0:
            logging.info('Cluster not found, creating...')
            cluster = self.api('post', 'cluster/', json=self.cluster)
            if cluster.status_code != 201:
                logging.critical('Cluster could not be created: {}: {}'.format(
                    cluster.status_code, cluster.text,
                ))
                return
            cluster = cluster.json()

        # Verify there are not duplicates
        if cluster.get('count', 0) != 1 and 'cluster_id' not in cluster:
            logging.critical('Invalid clusters detected, please check: {}'.format(cluster))
            return

        # Get the first and only cluster in the list
        if cluster.get('cluster_id', 0) == 0:
            cluster = cluster['results'][0]
        logging.info('Using cluster: {}'.format(cluster))

        # Merge Runs and Boottimes
        runs = runs.merge(boottime[['Boottime', 'TotalDesktops']], how='left', left_index=True, right_index=True)

        # Rename Results CSV columns to match database
        runs.rename({
            'TestName': 'testname',
            'DataTime': 'started',
            'BaseLine': 'loginvsi_base',
            'VSIMax': 'loginvsi_max',
            'Uncorrected': 'loginvsi_max_uncorrected',
            'VSIMaxDynamic': 'loginvsi_max_dynamic',
            'VSIMaxReached': 'loginvsi_max_reached',
            'LaunchedSessions': 'launched_sessions_cnt',
            'ActiveSessions': 'active_sessions_cnt',
            'Boottime': 'boot_time',
            'TotalDesktops': 'total_desktops',
        }, axis='columns', inplace=True)

        # Add extracted TestID
        runs['test_id'] = runs['testname'].str.extract(r'([\w\d\-]*)_.*')

        # Convert boot time to seconds
        runs['boot_time'] = pd.to_timedelta(runs['boot_time']).dt.total_seconds()

        # Add config variables to each Run
        runs['notes'] = self.config['TestName']
        runs['hv'] = self.config['HostingType']
        runs['hv_ver'] = self.config['HypervisorVersion']
        runs['aos_ver'] = self.config['AOSVersion']
        runs['tag'] = self.config['Tag']
        runs['loginvsi_ver'] = self.config['LoginVSIVersion']
        runs['loginvsi_workload_type'] = self.config['WorkloadType']
        runs['cluster_id'] = cluster['cluster_id']
        runs['desktop_broker'] = self.config['DeliveryType']
        runs['desktop_broker_ver'] = self.config['DesktopBrokerVersion']
        runs['desktop_broker_agent_ver'] = self.config['DesktopBrokerAgentVersion']
        runs['clone_type'] = self.config['CloneType']
        runs['session_cfg'] = self.config['SessionCfg']
        runs['target_platform'] = self.config['TargetPlatform']
        runs['target_os'] = self.config['TargetOS']
        runs['target_os_ver'] = self.config['TargetOSVersion']
        runs['tools_guest_ver'] = self.config['ToolsGuestVersion']
        runs['office_ver'] = self.config['OfficeVersion']
        runs['optimization_ver'] = self.config['OptimizationsVersion']
        runs['gpu_profile'] = self.config['GPUProfile']
        runs['vm_cnt'] = self.config['VMCount']
        runs['vm_cpu_cnt'] = self.config['VMCPUCount']
        runs['vm_mem_gb'] = self.config['VMMemoryGB']

        # Convert from Dataframe>JSON>Dictionary
        runs = json.loads(runs.to_json(orient='records', date_format='iso'))
        logging.info('Runs: {}'.format(runs))

        # Loop over all runs and post each
        for run in runs:
            r = self.api('post', 'loginvsi_run/', json=run)
            if r.status_code != 201:
                logging.critical('The run did not post correctly: {}: {}'.format(r.status_code, r.text))
                return
            logging.info('Run posted: {}'.format(r.json()))

        logging.info('Finished processing runs: {}'.format(len(runs)))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        prog='import_loginvsi',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description='Imports results from a set of LoginVSI Runs',
    )
    parser.add_argument(
        '-c', '--config', default='config.json',
        help='The file path to the JSON config file.',
    )
    parser.add_argument(
        '-r', '--results', default='results.csv',
        help='The file path to the CSV of run results.'
    )
    parser.add_argument(
        '-b', '--boottime', default='boottime.csv',
        help='The file path to the CSV of run boottime.'
    )
    # TODO abstract delete interface when providing "testname" or specific runid
    parser.add_argument(
        '-a', '--api', default='http://localhost:8080/api'
    )
    parser.add_argument(
        '-t', '--token', default='e33e36af7568d7b994408bbc8e9600a6546c7f75'
    )
    parser.add_argument(
        '-v', '--verbose', action='store_true',
        help='Adjust logging verbosity',
    )
    args = parser.parse_args()
    if args.verbose:
        logging.basicConfig(level=logging.DEBUG, format="%(asctime)s %(levelname)s: %(message)s")
    else:
        logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s: %(message)s")

    import_loginvsi = ImportLoginVSI(args)
    import_loginvsi.start()